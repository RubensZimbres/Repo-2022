# source /home/anaconda3/bin/activate torch

# pip install wandb

from datasets import load_dataset, load_metric
from transformers import Trainer
from transformers import TrainingArguments
from transformers import Wav2Vec2ForCTC

import torch
import numpy as np
import random
import librosa
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Union
from datasets import ClassLabel
import random
import pandas as pd
from transformers import Wav2Vec2CTCTokenizer
from transformers import Wav2Vec2FeatureExtractor
from transformers import Wav2Vec2Processor
import torchaudio
import re
import json
import wandb
import os

os.environ["WANDB_SILENT"] = "true"
os.environ["WANDB_DISABLED"] = "true"

try:
    import wandb
    from wandb import init, log, join  # test that these are available
except ImportError:
       print("msg")

common_voice_train = load_dataset("common_voice", "pt", split="train+validation")
common_voice_test = load_dataset("common_voice", "pt", split="test")

common_voice_train = common_voice_train.remove_columns(["accent", "client_id", "down_votes", "gender", "age","locale", "segment", "up_votes"]) #"gender", "age", 
common_voice_test = common_voice_test.remove_columns(["accent", "client_id", "down_votes", "gender", "age","locale", "segment", "up_votes"]) #"gender", "age", 

print(common_voice_train)



def show_random_elements(dataset, num_examples=10):
    assert num_examples <= len(dataset), "Can't pick more elements than there are in the dataset."
    picks = []
    for _ in range(num_examples):
        pick = random.randint(0, len(dataset)-1)
        while pick in picks:
            pick = random.randint(0, len(dataset)-1)
        picks.append(pick)

    df = pd.DataFrame(dataset[picks])
    print(df)

show_random_elements(common_voice_train)


def remove_special_characters(batch):
    batch["sentence"] = re.sub(r'[\W\s]', ' ', batch["sentence"]).lower() + " "
    return batch

common_voice_train = common_voice_train.map(remove_special_characters)
common_voice_test = common_voice_test.map(remove_special_characters)

show_random_elements(common_voice_train)

def extract_all_chars(batch):
  all_text = " ".join(batch["sentence"])
  vocab = list(set(all_text))
  return {"vocab": [vocab], "all_text": [all_text]}

vocab_train = common_voice_train.map(extract_all_chars, batched=True, batch_size=-1, keep_in_memory=True, remove_columns=common_voice_train.column_names)
vocab_test = common_voice_test.map(extract_all_chars, batched=True, batch_size=-1, keep_in_memory=True, remove_columns=common_voice_test.column_names)

vocab_list = vocab_list = [' ','a','b','c','d','e','f','g','h','i','j','l','m','n','o','p','q','r','s','t','u','v','x','z','á','é','ó','ê','ô','ç','ã','õ']

vocab_dict = {v: k for k, v in enumerate(vocab_list)}
print(vocab_dict)

vocab_dict["|"] = vocab_dict[" "]
del vocab_dict[" "]
vocab_dict["[UNK]"] = len(vocab_dict)
vocab_dict["[PAD]"] = len(vocab_dict)
print(len(vocab_dict))

with open('/home/theone/other_models/Wav2Vec/vocab.json', 'w') as vocab_file:
    json.dump(vocab_dict, vocab_file)


tokenizer = Wav2Vec2CTCTokenizer("/home/theone/other_models/Wav2Vec/vocab22.json", unk_token="[UNK]", pad_token="[PAD]", word_delimiter_token="|")


feature_extractor = Wav2Vec2FeatureExtractor(feature_size=1, sampling_rate=8000, padding_value=0.0, do_normalize=True, return_attention_mask=True)

processor = Wav2Vec2Processor(feature_extractor=feature_extractor, tokenizer=tokenizer)

processor.save_pretrained("/home/theone/other_models/Wav2Vec/hugging-xlsr/wav2vec2-large-xlsr-PTBR-demo")

output_dir="/home/theone/other_models/Wav2Vec/hugging-xlsr/wav2vec2-large-xlsr-PTBR-demo"

print(common_voice_train[0])


def speech_file_to_array_fn(batch):
    speech_array, sampling_rate = torchaudio.load(batch["path"])
    batch["speech"] = speech_array[0].numpy()
    batch["sampling_rate"] = sampling_rate
    batch["target_text"] = batch["sentence"]
    return batch

### 3:00

common_voice_train = common_voice_train.map(speech_file_to_array_fn, remove_columns=common_voice_train.column_names)
common_voice_test = common_voice_test.map(speech_file_to_array_fn, remove_columns=common_voice_test.column_names)


def resample(batch):
    batch["speech"] = librosa.resample(np.asarray(batch["speech"]), 48_000, 8_000)
    batch["sampling_rate"] = 8_000
    return batch

### 14:00 ###############################

common_voice_train = common_voice_train.map(resample, num_proc=4)
common_voice_test = common_voice_test.map(resample, num_proc=4)

show_random_elements(common_voice_train)

common_voice_train[0]



rand_int = random.randint(0, len(common_voice_train))
#ipd.Audio(data=np.asarray(common_voice_train[rand_int]["speech"]), autoplay=True, rate=16000)

rand_int = random.randint(0, len(common_voice_train))

print("Target text:", common_voice_train[rand_int]["target_text"])
print("Input array shape:", np.asarray(common_voice_train[rand_int]["speech"]).shape)
print("Sampling rate:", common_voice_train[rand_int]["sampling_rate"])

def prepare_dataset(batch):
    assert (
        len(set(batch["sampling_rate"])) == 1
    ), f"Make sure all inputs have the same sampling rate of {processor.feature_extractor.sampling_rate}."

    batch["input_values"] = processor(batch["speech"], sampling_rate=batch["sampling_rate"][0]).input_values

    with processor.as_target_processor():
        batch["labels"] = processor(batch["target_text"]).input_ids
    return batch

############# 1:20 

common_voice_train = common_voice_train.map(prepare_dataset, remove_columns=common_voice_train.column_names, batch_size=8, num_proc=4, batched=True)
common_voice_test = common_voice_test.map(prepare_dataset, remove_columns=common_voice_test.column_names, batch_size=8, num_proc=4, batched=True)


@dataclass
class DataCollatorCTCWithPadding:
    """
    Data collator that will dynamically pad the inputs received.
    Args:
        processor (:class:`~transformers.Wav2Vec2Processor`)
            The processor used for proccessing the data.
        padding (:obj:`bool`, :obj:`str` or :class:`~transformers.tokenization_utils_base.PaddingStrategy`, `optional`, defaults to :obj:`True`):
            Select a strategy to pad the returned sequences (according to the model's padding side and padding index)
            among:
            * :obj:`True` or :obj:`'longest'`: Pad to the longest sequence in the batch (or no padding if only a single
              sequence if provided).
            * :obj:`'max_length'`: Pad to a maximum length specified with the argument :obj:`max_length` or to the
              maximum acceptable input length for the model if that argument is not provided.
            * :obj:`False` or :obj:`'do_not_pad'` (default): No padding (i.e., can output a batch with sequences of
              different lengths).
        max_length (:obj:`int`, `optional`):
            Maximum length of the ``input_values`` of the returned list and optionally padding length (see above).
        max_length_labels (:obj:`int`, `optional`):
            Maximum length of the ``labels`` returned list and optionally padding length (see above).
        pad_to_multiple_of (:obj:`int`, `optional`):
            If set will pad the sequence to a multiple of the provided value.
            This is especially useful to enable the use of Tensor Cores on NVIDIA hardware with compute capability >=
            7.5 (Volta).
    """

    processor: Wav2Vec2Processor
    padding: Union[bool, str] = True
    max_length: Optional[int] = None
    max_length_labels: Optional[int] = None
    pad_to_multiple_of: Optional[int] = None
    pad_to_multiple_of_labels: Optional[int] = None

    def __call__(self, features: List[Dict[str, Union[List[int], torch.Tensor]]]) -> Dict[str, torch.Tensor]:
        input_features = [{"input_values": feature["input_values"]} for feature in features]
        label_features = [{"input_ids": feature["labels"]} for feature in features]

        batch = self.processor.pad(
            input_features,
            padding=self.padding,
            max_length=self.max_length,
            pad_to_multiple_of=self.pad_to_multiple_of,
            return_tensors="pt",
        )
        with self.processor.as_target_processor():
            labels_batch = self.processor.pad(
                label_features,
                padding=self.padding,
                max_length=self.max_length_labels,
                pad_to_multiple_of=self.pad_to_multiple_of_labels,
                return_tensors="pt",
            )

        labels = labels_batch["input_ids"].masked_fill(labels_batch.attention_mask.ne(1), -100)

        batch["labels"] = labels

        return batch

data_collator = DataCollatorCTCWithPadding(processor=processor, padding=True)

wer_metric = load_metric("wer")

def compute_metrics(pred):
    pred_logits = pred.predictions
    pred_ids = np.argmax(pred_logits, axis=-1)

    pred.label_ids[pred.label_ids == -100] = processor.tokenizer.pad_token_id

    pred_str = processor.batch_decode(pred_ids)

    label_str = processor.batch_decode(pred.label_ids, group_tokens=False)

    wer = wer_metric.compute(predictions=pred_str, references=label_str)

    return {"wer": wer}

model = Wav2Vec2ForCTC.from_pretrained(
    "facebook/wav2vec2-base", #LR 1e-03, #"facebook/wav2vec2-large-xlsr-53",
    attention_dropout=0.1,
    hidden_dropout=0.1,
    feat_proj_dropout=0.0,
    mask_time_prob=0.05,
    layerdrop=0.1,
    gradient_checkpointing=True,
    ctc_loss_reduction="mean",
    pad_token_id=processor.tokenizer.pad_token_id,
    vocab_size=len(processor.tokenizer)
)


model.freeze_feature_extractor()


training_args = TrainingArguments(
  output_dir="/home/theone/other_models/Wav2Vec/out/Base",
  group_by_length=True,
  per_device_train_batch_size=8,
  gradient_accumulation_steps=2,
  evaluation_strategy="steps",
  num_train_epochs=28,
  fp16=True,
  save_steps=500,
  eval_steps=2000,
  logging_steps=200,
  learning_rate=0.9e-4, ### 0.7e-5
  #weight_decay=0.0002,
  warmup_steps=200,
  save_total_limit=10,
  push_to_hub=False,
)

## ERRO AQUI no transformers old
trainer = Trainer(
    model=model,
    data_collator=data_collator,
    args=training_args,
    compute_metrics=compute_metrics,
    train_dataset=common_voice_train,
    eval_dataset=common_voice_test,
    tokenizer=processor.feature_extractor,
)

trainer.train()


len(list(model.named_modules()))
#201 layers

model_parameters = filter(lambda p: p.requires_grad == True, model.parameters())
params = sum([np.prod(p.size()) for p in model_parameters])
print(params)
x=90195103+4200448
print(x)
# GOAL 4.8/8.2 WER

{'loss': 2.8632, 'learning_rate': 8.813279950083196e-05, 'epoch': 0.86}                                                                                    
{'loss': 2.3258, 'learning_rate': 8.719685940099835e-05, 'epoch': 1.15}      
