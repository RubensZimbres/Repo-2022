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

common_voice_test = load_dataset("common_voice", "pt", split="test")

common_voice_test = common_voice_test.remove_columns(["accent", "client_id", "down_votes", "gender", "age","locale", "segment", "up_votes"]) #"gender", "age", 




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



def remove_special_characters(batch):
    batch["sentence"] = re.sub(r'[\W\s]', ' ', batch["sentence"]).lower() + " "
    return batch

common_voice_test = common_voice_test.map(remove_special_characters)

show_random_elements(common_voice_test)

def extract_all_chars(batch):
  all_text = " ".join(batch["sentence"])
  vocab = list(set(all_text))
  return {"vocab": [vocab], "all_text": [all_text]}


vocab_list = vocab_list = ['a','b','c','d','e','f','g','h','i','j','l','m','n','o','p','q','r','s','t','u','v','x','z','á','é','ó','ê','ô']

vocab_dict = {v: k for k, v in enumerate(vocab_list)}
print(vocab_dict)

#vocab_dict["|"] = vocab_dict[" "]
#del vocab_dict[" "]
#vocab_dict["[UNK]"] = len(vocab_dict)
#vocab_dict["[PAD]"] = len(vocab_dict)
#print(len(vocab_dict))

with open('/home/theone/other_models/Wav2Vec/vocab.json', 'w') as vocab_file:
    json.dump(vocab_dict, vocab_file)


tokenizer = Wav2Vec2CTCTokenizer("./vocab.json", unk_token=" ",word_delimiter_token=" ") #unk_token="[UNK], pad_token="[PAD]"",


feature_extractor = Wav2Vec2FeatureExtractor(feature_size=1, sampling_rate=16000, padding_value=0.0, do_normalize=True, return_attention_mask=True)

processor = Wav2Vec2Processor(feature_extractor=feature_extractor, tokenizer=tokenizer)

processor.save_pretrained("/home/theone/other_models/Wav2Vec/hugging-xlsr/wav2vec2-large-xlsr-PTBR-demo")

output_dir="/home/theone/other_models/Wav2Vec/hugging-xlsr/wav2vec2-large-xlsr-PTBR-demo"

print(common_voice_test[0])


def speech_file_to_array_fn(batch):
    speech_array, sampling_rate = torchaudio.load(batch["path"])
    batch["speech"] = speech_array[0].numpy()
    batch["sampling_rate"] = sampling_rate
    batch["target_text"] = batch["sentence"]
    return batch

### 3:00

common_voice_test = common_voice_test.map(speech_file_to_array_fn)


def resample(batch):
    batch["speech"] = librosa.resample(np.asarray(batch["speech"]), 48_000, 16_000)
    batch["sampling_rate"] = 16_000
    return batch

### 14:00 ###############################

common_voice_test = common_voice_test.map(resample, num_proc=4)

show_random_elements(common_voice_test)




def prepare_dataset(batch):
    assert (
        len(set(batch["sampling_rate"])) == 1
    ), f"Make sure all inputs have the same sampling rate of {processor.feature_extractor.sampling_rate}."

    batch["input_values"] = processor(batch["speech"], sampling_rate=batch["sampling_rate"][0]).input_values

    with processor.as_target_processor():
        batch["labels"] = processor(batch["target_text"]).input_ids
    return batch

############# 1:20 

common_voice_test = common_voice_test.map(prepare_dataset, batch_size=8, num_proc=4, batched=True)


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

model = Wav2Vec2ForCTC.from_pretrained("/home/theone/other_models/Wav2Vec/out/wav2vec2-large-xlsr-PTBR-demo/2/checkpoint-38500")
model.to("cuda")


show_random_elements(common_voice_test)


# Preprocessing the datasets.
# We need to read the aduio files as arrays
def evaluate(batch):
	inputs = processor(batch["speech"], sampling_rate=16_000, return_tensors="pt", padding=True)

	with torch.no_grad():
		pred_ids = torch.argmax(model(inputs.input_values.to("cuda"), attention_mask=inputs.attention_mask.to("cuda")).logits,dim=-1)
	batch["pred_strings"] = processor.batch_decode(pred_ids)
	return batch

result = common_voice_test.map(evaluate, batched=True, batch_size=8)

print("WER: {:2f}".format(100 * wer_metric.compute(predictions=result["pred_strings"], references=result["sentence"])))

result["sentence"][-2]
result["pred_strings"][-2]
