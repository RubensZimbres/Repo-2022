import seaborn as sns
from sklearn.metrics import pairwise

import tensorflow as tf
import tensorflow_hub as hub
import tensorflow_text as text  # Imports TF ops for preprocessing.


BERT_MODEL = "https://tfhub.dev/tensorflow/bert_multi_cased_L-12_H-768_A-12/4"

PREPROCESS_MODEL = "https://tfhub.dev/tensorflow/bert_en_uncased_preprocess/3"

sentences = [
  "Here We Go Then, You And I is a 1999 album by Norwegian pop artist Morten Abel. It was Abel's second CD as a solo artist.",
  "If it rains, it pours.", "The quick brown fox jumps over the lazy dog."]

preprocess = hub.load(PREPROCESS_MODEL)
bert = hub.load(BERT_MODEL)

inputs = preprocess(sentences)
outputs = bert(inputs)


print(outputs["pooled_output"].shape)

print(outputs["sequence_output"].shape)

import matplotlib.pyplot as plt

def plot_similarity(features, labels):
  """Plot a similarity matrix of the embeddings."""
  cos_sim = pairwise.cosine_similarity(features)
  sns.set(font_scale=1.2)
  cbar_kws=dict(use_gridspec=False, location="left")
  g = sns.heatmap(
      cos_sim, xticklabels=labels, yticklabels=labels,
      vmin=0, vmax=1, cmap="Blues", cbar_kws=cbar_kws)
  g.tick_params(labelright=True, labelleft=False)
  g.set_yticklabels(labels, rotation=0)
  g.set_title("Semantic Textual Similarity")
  plt.show()
  
plot_similarity(outputs["pooled_output"], sentences)



