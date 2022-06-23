#source https://github.com/MaartenGr/KeyBERT

from keybert import KeyBERT
from sentence_transformers import SentenceTransformer

sentence_model = SentenceTransformer('sentence-transformers/distiluse-base-multilingual-cased-v1')


kw_model = KeyBERT(model=sentence_model)
keywords = kw_model.extract_keywords(article_text, keyphrase_ngram_range=(1, 1), stop_words=None,top_n=5)
print(keywords)

