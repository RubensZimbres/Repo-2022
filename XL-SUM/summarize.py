#https://huggingface.co/csebuetnlp/mT5_multilingual_XLSum?text=

import re
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

WHITESPACE_HANDLER = lambda k: re.sub('\s+', ' ', re.sub('\n+', ' ', k.strip()))

article_text = """
Com a redução da carga tributária, o cenário fiscal torna-se mais desafiador, de acordo com as economistas do Bradesco Mariana Freitas e Myriã Bast, em relatório divulgado nesta quarta-feira, 22.
E segundo as duas, "ao incorporar as perdas de receita oriundas do PLP-18 e da PEC dos combustíveis, nossa estimativa para a dívida pública se aproxima de 90% do PIB em 2027, mesmo considerando o cumprimento do teto de gastos, agora mais restritivo diante de uma inflação menor".
Em um segundo cenário, onde todas as desonerações presentes nos projetos se tornam permanentes, a piora da dívida é da ordem de 10 pontos porcentuais até 2027, preveem Mariana e Myriã.
"É importante mencionar que a tentativa de conter os efeitos inflacionários decorrentes do aumento de petróleo e combustíveis tem sido observada em vários países. Utilizar parte das receitas extraordinárias para atenuar esse choque inflacionário não previsto é compreensível, ainda mais diante de surpresas recorrentes com arrecadação, especialmente aquelas associadas ao setor de petróleo", avaliam as duas economistas.
Ao mesmo tempo, de acordo com Mariana e Myriã, ao optar por desonerações não focalizadas e fora do escopo de uma reforma tributária mais ampla, perde-se a oportunidade de construir regime tributário que ofereça maior racionalidade para os tributos federais e estaduais e maior competitividade para a economia.
"""


model_name = "csebuetnlp/mT5_multilingual_XLSum"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name)

input_ids = tokenizer(
    [WHITESPACE_HANDLER(article_text)],
    return_tensors="pt",
    padding="max_length",
    truncation=True,
    max_length=512
)["input_ids"]

output_ids = model.generate(
    input_ids=input_ids,
    max_length=84,
    no_repeat_ngram_size=2,
    num_beams=4
)[0]

summary = tokenizer.decode(
    output_ids,
    skip_special_tokens=True,
    clean_up_tokenization_spaces=False
)

print(summary)

@inproceedings{hasan-etal-2021-xl,
    title = "{XL}-Sum: Large-Scale Multilingual Abstractive Summarization for 44 Languages",
    author = "Hasan, Tahmid  and
      Bhattacharjee, Abhik  and
      Islam, Md. Saiful  and
      Mubasshir, Kazi  and
      Li, Yuan-Fang  and
      Kang, Yong-Bin  and
      Rahman, M. Sohel  and
      Shahriyar, Rifat",
    booktitle = "Findings of the Association for Computational Linguistics: ACL-IJCNLP 2021",
    month = aug,
    year = "2021",
    address = "Online",
    publisher = "Association for Computational Linguistics",
    url = "https://aclanthology.org/2021.findings-acl.413",
    pages = "4693--4703",
}
