###### DEPLOY OUTSIDE ANN

import os
import pprint
import tempfile
# (BASE)
from typing import Dict, Text
import numpy as np
import tensorflow as tf
#import tensorflow_datasets as tfds
import tensorflow_recommenders as tfrs  #scann 1.2.7 + recomm 0.7.0 + TF 2.8.0
from google.cloud import bigquery ## version 0.30.0
import os
from google.oauth2 import service_account
import unidecode
from nltk import word_tokenize
import re
import pandas as pd
from nltk.util import ngrams
import base64
import hashlib


'''tf.__version__ == "2.9.1"
tfrs.__version__ == "v0.7.0"'''

# pip install tensorflow==2.9.1
# pip install tensorflow-text
# pip install scann
# pip3 install numpy --ignore-installed
# pip install tensorflow-recommenders

#os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/home/user/XXX.json'
#credentials = service_account.Credentials.from_service_account_file("'/home/user/XXX.json'")
#bqclient = bigquery.Client(credentials=credentials)


#query_string = """SELECT Key.id_vacante,titulo_oe,nivel_estudio,observaciones,codigo_postal,requisito,experiencia FROM  `project.dataset.table` 
#AS Key LEFT JOIN (SELECT id_vacante,competencia_limpia FROM `project.dataset.competencias_vacantes`) AS Value ON Key.id_vacante=Value.id_vacante
#"""

#dataframe = (
 #   bqclient.query(query_string)
  #  .result()
   # .to_dataframe(
    #    create_bqstorage_client=True,
    #)
#)

#df=dataframe.dropna().iloc[1:,:]#.to_dict('list')

#df.columns


dataframe=pd.read_csv('/home/user/modelo_mineracao_4.csv',sep=',',header=0)
df=dataframe.iloc[:,0:-2]
df

df.columns=['Site ', 'nome_vaga', 'nome_empresa', 'tamanho_empresa',
       'linguagem', 'pais', 'estado', 'cidade', 'descricao',
       'beneficios', 'diversidade', 'data da postagem', 'requisito_1',
       'requisito_2', 'requisito_3', 'requisito_4', 'requisito_5',
       'requisito_6', 'requisito_7', 'requisito_8', 'requisito_9',
       'requisito_10', 'requisito_11', 'requisito_12', 'requisito_13',
       'requisito_14', 'requisito_15']




df['descricao']=df['descricao'].map(lambda x: re.sub(r'[\W\s]', ' ', str(x)).lower()).astype(str).map(lambda x: (''.join(unidecode.unidecode(x))))

df["requisito"] = df['linguagem']+' '+df['pais']+' '+df['estado']+' '+df['tamanho_empresa']+' '+df['beneficios']+' '+df['cidade']+' '+df['diversidade']+' '+df['descricao']+' '+df["requisito_1"] + ' ' + df["requisito_2"]+ ' ' + df["requisito_3"]+ ' ' + df["requisito_4"]+ ' ' + df["requisito_5"]+ ' ' + df["requisito_6"]+ ' ' + df["requisito_7"]+ ' ' + df["requisito_8"]+ ' ' + df["requisito_9"]+ ' ' + df["requisito_10"]+ ' ' + df["requisito_11"]+ ' ' + df["requisito_12"]+ ' ' + df["requisito_13"]+ ' ' + df["requisito_14"]+ ' ' + df["requisito_15"]

df["requisito"]= df["requisito"].map(lambda x: str(x).replace("\r","").replace("\n",""))

import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/home/user/XXX.json"

import time
def translate_text(target, text):
    time.sleep(0.5)
    import six
    from google.cloud import translate_v2 as translate

    translate_client = translate.Client()

    if isinstance(text, six.binary_type):
        text = text.decode("utf-8")

    # Text can also be a sequence of strings, in which case this method
    # will return a sequence of results for each text.
    result = translate_client.translate(text, target_language=target)

    #print(u"Text: {}".format(result["input"]))
    #print(result["translatedText"])
    #print(u"Detected source language: {}".format(result["detectedSourceLanguage"]))
    return result["translatedText"]


import time
'''for i in range(0,df.shape[0]):
    time.sleep(0.4)
    print(i)
    df["requisito"].iloc[i]=translate_text("en",df["requisito"].iloc[i])'''


## STOP

df["requisito"]=df['requisito'].map(lambda x: ' '.join([i for i in word_tokenize(str(x)) if len(i)>3]))

df['requisito']=df['requisito'].map(lambda x: re.sub(r'[\W\s]', ' ', str(x)).lower()).astype(str).map(lambda x: (''.join(unidecode.unidecode(x))+2500*' zero')[:3000])

###############

df['nome_vaga']=df['nome_vaga'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['nome_empresa']=df['nome_empresa'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['tamanho_empresa']=df['tamanho_empresa'].astype(str).map(lambda x: unidecode.unidecode(x))
df['linguagem']=df['linguagem'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['pais']=df['pais'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['estado']=df['estado'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['cidade']=df['cidade'].astype(str).map(lambda x: ''.join(unidecode.unidecode(x)))
df['beneficios']=df['beneficios'].astype(str).map(lambda x: (''.join(unidecode.unidecode(x))+400*' zero')[:400])
df['diversidade']=df['diversidade'].astype(str).map(lambda x: (''.join(unidecode.unidecode(x))+400*' zero')[:400])

df['vagas']=df['nome_vaga']+' '+df['nome_empresa']+' '+df['tamanho_empresa']+' '+df['linguagem']+' '+df['pais']+' '+df['estado']+' '+df['cidade']+' '+df['descricao']+' '+df['beneficios']+' '+df['diversidade']
df['vagas']=df['vagas'].map(lambda x: re.sub(r'[\W\s]', ' ', str(x)).lower()).astype(str).map(lambda x: (''.join(unidecode.unidecode(x))+300*' zero')[:500])

df['vagas'].iloc[0]

df['code']=df["requisito"].map(lambda x: base64.b64encode(hashlib.md5(x.encode('utf-8')).digest()))


#df['requisito']=df['requisito'].astype(str).map(lambda x: np.concatenate([np.array(word_tokenize(str(x))[1:-2]).astype(str),np.zeros((1,30))[0]])).astype(str)

#df=pd.concat([df.reset_index(),pd.DataFrame(df['requisito'].to_list()).reset_index()],axis=1)


df=df[['code','vagas', 'nome_vaga','nome_empresa', 'tamanho_empresa', 'linguagem',
       'pais', 'estado', 'cidade', 'descricao', 'beneficios', 'diversidade',
       'data da postagem',
       'requisito']]





'''for i in range(0,df.shape[0]):
    time.sleep(0.4)
    print(i)
    df["nome_vaga"].iloc[i]=translate_text("en",df["nome_vaga"].iloc[i])'''


# TEST

df["requisito"].iloc[298]

df["nome_vaga"]

#df.to_csv("/home/user/XXX_translated_best_2500_bckp.csv",sep=",",index=False, columns=df.columns)



df=pd.read_csv("/home/user/XXX_translated_best_2500.csv",sep=",",header=0)

for i in range(0,len(df['requisito'])):
    print(len(df['requisito'].iloc[i]))

df=df.drop_duplicates()
df=df.dropna()

df["nome_vaga"]=df["nome_vaga"].map(lambda x: x.lower().title())
df["requisito"]=df["requisito"].map(lambda x: x[0:1000].lower())

df.code

tf.strings.split(df['requisito'].iloc[-1])
my_dict=dict(df.iloc[0:int(df.shape[0]*0.9),:])

my_dict_cego=dict(df.iloc[int(df.shape[0]*0.9):,:])


ratings = tf.data.Dataset.from_tensor_slices(my_dict).map(lambda x: {
    "code": x["code"],
    "nome_vaga": x["nome_vaga"],
    "requisito": tf.strings.split(x["requisito"],maxsplit=106)
})

l=[]
for x in ratings.as_numpy_iterator():
    pprint.pprint(len(x['requisito']))
    l.append(len(x['requisito']))

min(l)


movies = tf.data.Dataset.from_tensor_slices(dict(df)).map(lambda x: {
    "code": x["code"],
    "nome_vaga": x["nome_vaga"]
})
for x in movies.take(1).as_numpy_iterator():
    pprint.pprint(x)

movies = movies.map(lambda x: x["code"])


for x in ratings.take(5).as_numpy_iterator():
    pprint.pprint(x)


for x in movies.take(5).as_numpy_iterator():
    pprint.pprint(x)

ratings_cego = tf.data.Dataset.from_tensor_slices(my_dict_cego).map(lambda x: {
    "code": x["code"],
    "requisito": tf.strings.split(x["requisito"],maxsplit=106)
})

tf.random.set_seed(42)
shuffled = ratings.shuffle(int(df.shape[0]*0.9), seed=42, reshuffle_each_iteration=False)
shuffled2 = ratings_cego.shuffle(int(df.shape[0]*0.1), seed=42, reshuffle_each_iteration=False)

train = shuffled.take(int(df.shape[0]*0.9))
test = shuffled.take(int(df.shape[0]*0.1))
cego=shuffled2

for x in train.take(1).as_numpy_iterator():
    pprint.pprint(x)

for x in test.take(5).as_numpy_iterator():
    pprint.pprint(x)




movie_titles = movies#.map(lambda x: x["code"])
user_ids = ratings.map(lambda x: x["requisito"])

xx=[]
for x in user_ids.as_numpy_iterator():
    try:
        #print(x)
        xx.append(x)
    except:
        pass



unique_movie_titles = np.unique(list(movie_titles.as_numpy_iterator()))

unique_user_ids = np.unique(np.concatenate(xx))

user_ids=user_ids.batch(int(df.shape[0]*0.9))

layer = tf.keras.layers.StringLookup(vocabulary=unique_user_ids)

for x in ratings.take(1).as_numpy_iterator():
    pprint.pprint(x['requisito'])

for x in ratings.take(5).as_numpy_iterator():
    pprint.pprint(np.array(layer(x['requisito'])))

unique_movie_titles[:10]

embedding_dimension = 768

user_model = tf.keras.Sequential([
  tf.keras.layers.StringLookup(
      vocabulary=unique_user_ids, mask_token=None),
  # We add an additional embedding to account for unknown tokens.
  tf.keras.layers.Embedding(len(unique_user_ids) + 1, embedding_dimension),
  
])

for x in train.take(5).as_numpy_iterator():
    pprint.pprint(np.array(user_model(x['requisito'])).shape)


movie_model = tf.keras.Sequential([
  tf.keras.layers.StringLookup(
      vocabulary=unique_movie_titles, mask_token=None),
  tf.keras.layers.Embedding(len(unique_movie_titles) + 1, embedding_dimension)
])

for x in train.take(5).as_numpy_iterator():
    pprint.pprint(np.array(movie_model(x['code'])).shape)


metrics = tfrs.metrics.FactorizedTopK(
  candidates=movies.batch(df.shape[0]
).map(movie_model)
)

task = tfrs.tasks.Retrieval(
  metrics=metrics
)


class MovielensModel(tfrs.Model):

  def __init__(self, user_model, movie_model):
    super().__init__()
    self.movie_model: tf.keras.Model = movie_model
    self.user_model: tf.keras.Model = user_model
    self.task: tf.keras.layers.Layer = task

  def compute_loss(self, features: Dict[Text, tf.Tensor], training=False) -> tf.Tensor:
    # We pick out the user features and pass them into the user model.
    user_embeddings = self.user_model(features["requisito"])
    # And pick out the movie features and pass them into the movie model,
    # getting embeddings back.
    positive_movie_embeddings = self.movie_model(features["code"])

    # The task computes the loss and the metrics.
    return self.task(tf.reduce_sum(user_embeddings,axis=1), positive_movie_embeddings)

class NoBaseClassMovielensModel(tf.keras.Model):

  def __init__(self, user_model, movie_model):
    super().__init__()
    self.movie_model: tf.keras.Model = movie_model
    self.user_model: tf.keras.Model = user_model
    self.task: tf.keras.layers.Layer = task

  def train_step(self, features: Dict[Text, tf.Tensor]) -> tf.Tensor:

    # Set up a gradient tape to record gradients.
    with tf.GradientTape() as tape:

      # Loss computation.
      user_embeddings = self.user_model(features["requisito"])
      positive_movie_embeddings = self.movie_model(features["code"])
      loss = self.task(user_embeddings, positive_movie_embeddings)

      # Handle regularization losses as well.
      regularization_loss = sum(self.losses)

      total_loss = loss + regularization_loss

    gradients = tape.gradient(total_loss, self.trainable_variables)
    self.optimizer.apply_gradients(zip(gradients, self.trainable_variables))

    metrics = {metric.name: metric.result() for metric in self.metrics}
    metrics["loss"] = loss
    metrics["regularization_loss"] = regularization_loss
    metrics["total_loss"] = total_loss

    return metrics

  def test_step(self, features: Dict[Text, tf.Tensor]) -> tf.Tensor:

    # Loss computation.
    user_embeddings = self.user_model(features["requisito"])
    positive_movie_embeddings = self.movie_model(features["code"])
    loss = self.task(user_embeddings, positive_movie_embeddings)

    # Handle regularization losses as well.
    regularization_loss = sum(self.losses)

    total_loss = loss + regularization_loss

    metrics = {metric.name: metric.result() for metric in self.metrics}
    metrics["loss"] = loss
    metrics["regularization_loss"] = regularization_loss
    metrics["total_loss"] = total_loss

    return metrics

model = MovielensModel(user_model, movie_model)
model.compile(optimizer=tf.keras.optimizers.Adagrad(learning_rate=0.08))
cached_train = train.shuffle(int(df.shape[0]*0.9)).batch(int(df.shape[0]*0.9)).cache()

cached_test = test.batch(int(df.shape[0]*0.1)).cache()

path = os.path.join("/home/theone/Downloads/other_models/Dubai/", "model/")


cp_callback = tf.keras.callbacks.ModelCheckpoint(
    filepath=path, 
    verbose=1, 
    save_weights_only=True,
    save_freq=2)


model.fit(cached_train, callbacks=[cp_callback],epochs=200)

model.evaluate(cached_test, return_dict=True)



######## OPCAO 2 DEPLOY VERTEX AI ******** GOOD

#https://github.com/google-research/google-research/blob/master/scann/docs/example.ipynb

#https://github.com/google-research/google-research/blob/master/scann/docs/algorithms.md

import gradio as gr
import scann

#campos="Spanish Colombia Quindio More than 10,000 experience call center and sales"

index=df["code"].map(lambda x: [model.movie_model(tf.constant(x))])

np.array(index)[1633][0]

from sklearn.metrics.pairwise import cosine_similarity

indice=[]
for i in range(0,1633):
    indice.append(np.array(index)[i][0])


#campos="Spanish Colombia Quindio experience call center sales administrative work".lower()

#query=np.sum([model.user_model(tf.constant(campos.split()[i])) for i in range(0,len(campos.split()))],axis=0)

searcher = scann.scann_ops_pybind.builder(np.array(indice), 10, "dot_product").tree(
    num_leaves=1500, num_leaves_to_search=500, training_sample_size=df.shape[0]).score_brute_force(
    2, quantize=True).build()

def predict(text):
    campos=str(text).lower()
    query=np.sum([model.user_model(tf.constant(campos.split()[i])) for i in range(0,len(campos.split()))],axis=0)
    neighbors, distances = searcher.search_batched([query])
    xx = df.iloc[neighbors[0],:].nome_vaga
    return xx


predict("Spanish Colombia Bogota experience call center sales administrative work")

predict("Spanish Colombia Bogota experience secretary administrative work")

predict("Spanish Colombia Bogota experience human resources assistant recruiting") #ESCO

predict("Spanish Colombia Bogota experience human resources assistant document interviews use communication techniques employment law") #ESCO


predict([ i for i in word_tokenize('''Spanish Colombia Bogota experience processing customer cash deposits and withdrawals, cheques, transfers, bills, credit card payments, money orders, certified cheques and other related banking transactions;
crediting and debiting clients’ accounts;
paying bills and making money transfers on clients’ behalf;
receiving mail, selling postage stamps and conducting other post office counter business such as bill payments, money transfers and related business;
changing money from one currency to another, as requested by clients;
making records of all transactions and reconciling them with cash balance.''') if len(i)>4])

predict([ i for i in word_tokenize('''Food preparation assistants prepare and cook to order a small variety of pre-cooked food or beverages, clear tables, clean kitchen areas and wash dishes.
Tasks performed usually include: preparing simple or pre-prepared foods and beverages such as sandwiches, pizzas, fish and chips, salads and coffee; washing, cutting, measuring and mixing foods for cooking; operating cooking equipment such as grills, microwaves and deep-fat fryers; cleaning kitchens, food preparation areas and service areas; cleaning cooking and general utensils used in kitchens and restaurants.''') if len(i)>4])

gr.__version__

demo = gr.Interface(fn=predict, inputs=gr.inputs.Textbox(label='Candidate Competences'), outputs=gr.outputs.Textbox(label='Suggested Vacancies'),css='body{background-image:url("file/https://drive.google.com/file/d/1IH467kY7b8kOBBkV_GO46pRxtbyFTw0v");}').launch(share=False)   
