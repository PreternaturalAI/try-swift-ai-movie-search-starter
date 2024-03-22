import pandas as pd
import re

# Function to preprocess titles (remove punctuation, convert to lowercase)
def preprocess_title(title):
    return re.sub(r'[^\w\s]', '', title).lower()

# Load the datasets
imdb_df = pd.read_csv('/Users/natashatherobot/Library/CloudStorage/Dropbox/NatashaTheRobot/AI/AIMovieSearch/csvDataProcessing/imdb_top_1000.csv')
wiki_df = pd.read_csv('/Users/natashatherobot/Library/CloudStorage/Dropbox/NatashaTheRobot/AI/AIMovieSearch/csvDataProcessing/wiki_movie_plots_deduped.csv')

# Preprocess the titles in both datasets for better matching
imdb_df['Processed_Title'] = imdb_df['Series_Title'].apply(preprocess_title)
wiki_df['Processed_Title'] = wiki_df['Title'].apply(preprocess_title)

# Initialize a column for plots in the IMDB DataFrame
imdb_df['Wiki_Plot'] = ''

# Attempt to match each IMDB movie with a Wiki plot
for index, row in imdb_df.iterrows():
    title = row['Processed_Title']
    year = row['Released_Year']
    print("TITLE: ", title)
    # Find matching titles and years in the wiki dataset
    matching_plots = wiki_df[(wiki_df['Processed_Title'] == title)]['Plot']
    print("MATCHING: ", matching_plots)
    if not matching_plots.empty:
        imdb_df.at[index, 'Wiki_Plot'] = matching_plots.iloc[0]  # Take the first match

# Optionally, drop the Processed_Title column if no longer needed
#imdb_df.drop('Processed_Title', axis=1, inplace=True)

# Save the merged DataFrame to a new CSV file
imdb_df.to_csv('/Users/natashatherobot/Library/CloudStorage/Dropbox/NatashaTheRobot/AI/AIMovieSearch/csvDataProcessing/imdb_with_wiki_plots.csv', index=False)
