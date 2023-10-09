CREATE OR REPLACE FUNCTION jaro_winkler_similarity(s1 text, s2 text) RETURNS double precision AS $$
DECLARE
    s1_len int := length(s1);
    s2_len int := length(s2);
    match_window int := floor(greatest(s1_len, s2_len) / 2) - 1;
    transpositions int := 0;
    common_chars text := '';
    max_prefix_len int := 0;
BEGIN
    IF s1_len = 0 OR s2_len = 0 THEN
        RETURN 0.0;
    END IF;
    
    -- Find common characters
    FOR i IN 1..s1_len LOOP
        FOR j IN greatest(1, i - match_window)..least(s2_len, i + match_window) LOOP
            IF substring(s1 from i for 1) = substring(s2 from j for 1) THEN
                common_chars := common_chars || substring(s1 from i for 1);
                IF i = j THEN
                    transpositions := transpositions + 1;
                END IF;
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    
    IF common_chars = '' THEN
        RETURN 0.0;
    END IF;
    
    -- Calculate the Jaro distance
    DECLARE jaro_distance double precision := (length(common_chars) / s1_len + length(common_chars) / s2_len + (length(common_chars) - transpositions) / length(common_chars)) / 3;
    
    -- Calculate the Jaro-Winkler distance with a prefix scale factor (0.1 by default)
    DECLARE prefix_scale_factor double precision := 0.1;
    SELECT max(prefix_len) INTO max_prefix_len FROM (SELECT length(common_chars) - position(common_chars in s1) as prefix_len UNION SELECT length(common_chars) - position(common_chars in s2)) AS prefix_lens;
    
    RETURN jaro_distance + max_prefix_len * prefix_scale_factor * (1 - jaro_distance);
END;
$$ LANGUAGE plpgsql;

-- Example usage:
SELECT jaro_winkler_similarity('DIXON', 'DICKSONX'); -- Should return a value close to 0.8133
