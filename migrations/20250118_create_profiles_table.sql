-- Create profiles table with error handling
DO $$
DECLARE
BEGIN
BEGIN
    -- Create table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'profiles') THEN
        CREATE TABLE profiles (
            id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
            first_name TEXT,
            last_name TEXT,
            country_of_origin TEXT,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
            CONSTRAINT unique_profile_id UNIQUE (id)
        );
    END IF;

    -- Enable Row Level Security if not already enabled
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Enable RLS for profiles'
    ) THEN
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    END IF;

    -- Policy: Users can update their own profile
    -- Only allows updates where the user ID matches the profile ID
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can update their own profile'
    ) THEN
        CREATE POLICY "Users can update their own profile"
        ON profiles FOR UPDATE
        USING (auth.uid() = id);
    END IF;

    -- Policy: Users can view their own profile
    -- Only allows viewing of the user's own profile
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can view their own profile'
    ) THEN
        CREATE POLICY "Users can view their own profile"
        ON profiles FOR SELECT
        USING (auth.uid() = id);
    END IF;

    -- Policy: Users can insert their own profile
    -- Only allows insertion of profiles where the ID matches the user's ID
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can insert their own profile'
    ) THEN
        CREATE POLICY "Users can insert their own profile"
        ON profiles FOR INSERT
        WITH CHECK (auth.uid() = id);
    END IF;
END $$ LANGUAGE plpgsql;
