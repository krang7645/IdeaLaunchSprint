// server/index.js
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { createClient } = require('@supabase/supabase-js');
const { Configuration, OpenAIApi } = require('openai');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
const port = process.env.PORT || 3000;

// Apply middleware
app.use(cors());
app.use(express.json());

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Initialize OpenAI configuration
const openaiConfig = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(openaiConfig);

// Rate limiting middleware
const apiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again later.',
});

// Rate limiting for free tier
const freeTierLimiter = rateLimit({
  windowMs: 30 * 24 * 60 * 60 * 1000, // 30 days
  max: 30, // 30 requests per month
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Free tier quota exceeded. Please upgrade to Pro for unlimited usage.',
  keyGenerator: (req) => req.user.id, // Use user ID as key
});

// Authentication middleware
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verify token with Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    
    // Add user to request
    req.user = user;
    
    // Check subscription tier
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('subscription_tier')
      .eq('id', user.id)
      .single();
    
    if (profileError || !profile) {
      return res.status(403).json({ error: 'User profile not found' });
    }
    
    req.user.subscription_tier = profile.subscription_tier;
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(500).json({ error: 'Authentication failed' });
  }
};

// Apply rate limiting to API routes
app.use('/api', authenticate, apiLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// OpenAI chat completion proxy
app.post('/api/openai/chat', async (req, res) => {
  try {
    // Apply free tier limits if not a pro subscriber
    if (req.user.subscription_tier !== 'pro') {
      freeTierLimiter(req, res, async () => {
        await processOpenAiRequest(req, res);
      });
    } else {
      await processOpenAiRequest(req, res);
    }
  } catch (error) {
    console.error('Error proxying to OpenAI:', error);
    res.status(500).json({ error: 'Failed to process OpenAI request' });
  }
});

// Function to process OpenAI request
async function processOpenAiRequest(req, res) {
  try {
    const { messages, temperature = 0.7, max_tokens, model = 'gpt-4' } = req.body;
    
    // Log the request (for monitoring usage)
    await supabase.from('api_logs').insert({
      user_id: req.user.id,
      endpoint: 'openai/chat',
      request_size: JSON.stringify(messages).length,
      subscription_tier: req.user.subscription_tier,
    });
    
    // Make the request to OpenAI
    const response = await openai.createChatCompletion({
      model,
      messages,
      temperature,
      max_tokens,
    });
    
    // Return the response
    res.status(200).json(response.data);
  } catch (error) {
    console.error('Error calling OpenAI:', error);
    res.status(500).json({ error: 'Failed to call OpenAI API' });
  }
}

// Handle 404
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

// server/.env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_supabase_service_key
OPENAI_API_KEY=your_openai_api_key
PORT=3000

// server/package.json
{
  "name": "launchpad-notebook-backend",
  "version": "0.1.0",
  "description": "Backend proxy server for LaunchPad Notebook",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "MIT",
  "dependencies": {
    "@supabase/supabase-js": "^2.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "jsonwebtoken": "^9.0.0",
    "openai": "^3.2.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}

// server/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "index.js"]