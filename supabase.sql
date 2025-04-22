-- Create an ideas table
CREATE TABLE ideas (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('active', 'archived', 'published')),
  step TEXT NOT NULL CHECK (step IN ('capture', 'validate', 'build', 'publish')),
  expire_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create RLS policies for ideas table
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own ideas"
  ON ideas FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own ideas"
  ON ideas FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ideas"
  ON ideas FOR UPDATE
  USING (auth.uid() = user_id);

-- Create idea_details table
CREATE TABLE idea_details (
  idea_id UUID PRIMARY KEY REFERENCES ideas ON DELETE CASCADE,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  answers JSONB,
  todos JSONB,
  platform TEXT
);

-- Create RLS policies for idea_details table
ALTER TABLE idea_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view details of their own ideas"
  ON idea_details FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM ideas
    WHERE ideas.id = idea_details.idea_id
    AND ideas.user_id = auth.uid()
  ));

CREATE POLICY "Users can insert details for their own ideas"
  ON idea_details FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM ideas
    WHERE ideas.id = idea_details.idea_id
    AND ideas.user_id = auth.uid()
  ));

CREATE POLICY "Users can update details of their own ideas"
  ON idea_details FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM ideas
    WHERE ideas.id = idea_details.idea_id
    AND ideas.user_id = auth.uid()
  ));

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Create a trigger to call the function before update
CREATE TRIGGER update_ideas_updated_at
BEFORE UPDATE ON ideas
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a cron job to automatically archive expired ideas
-- Note: This requires pg_cron extension to be enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule('0 * * * *', $
  UPDATE ideas
  SET state = 'archived'
  WHERE state = 'active'
  AND expire_at < now();
$);

-- Create a notification function
CREATE OR REPLACE FUNCTION notify_idea_archived()
RETURNS TRIGGER AS $
BEGIN
  -- In a real implementation, this would send a push notification
  -- For MVP, we just insert into a notifications table
  INSERT INTO notifications (user_id, message)
  VALUES (NEW.user_id, format('"%s" が期限切れでアーカイブされました', 
                             (SELECT title FROM idea_details WHERE idea_id = NEW.id)));
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Create notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create RLS policies for notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Create a trigger to call the notification function after update
CREATE TRIGGER notify_idea_archived_trigger
AFTER UPDATE ON ideas
FOR EACH ROW
WHEN (OLD.state = 'active' AND NEW.state = 'archived')
EXECUTE FUNCTION notify_idea_archived();