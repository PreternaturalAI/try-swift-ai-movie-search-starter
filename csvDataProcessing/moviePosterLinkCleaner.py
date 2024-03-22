import pandas as pd
import re

# Load the dataset
file_path = '/Users/natashatherobot/Library/CloudStorage/Dropbox/NatashaTheRobot/AI/AIMovieSearch/csvDataProcessing/imdb_with_wiki_plots.csv'
df = pd.read_csv(file_path)

# Function to remove sizing information from a poster link
def process_poster_link(link):
    # Extended regular expression to find both sizing and CR patterns
    pattern = r'(_V1_).*?(_AL_|\.jpg)'
    # Replace found patterns to only keep the part up to '_AL_' or '.jpg'
    new_link = re.sub(pattern, r'\1_AL_\2', link)
    if new_link.endswith('_AL_.jpg'):  # Adjust for links directly ending with .jpg
        new_link = new_link.replace('_AL_.jpg', '.jpg')
    return new_link

# Apply the function to each Poster_Link and store the result in a new column
df['Poster_Link_Large'] = df['Poster_Link'].apply(process_poster_link)

# Save the DataFrame with the new column to a new CSV file
output_path = '/Users/natashatherobot/Library/CloudStorage/Dropbox/NatashaTheRobot/AI/AIMovieSearch/csvDataProcessing/imdb_with_wiki_plots_large_posters.csv'
df.to_csv(output_path, index=False)
