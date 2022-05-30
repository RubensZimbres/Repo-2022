response = openai.Completion.create(
  engine="text-davinci-002",
  prompt=text0,
  temperature=0.3,
  max_tokens=150,
  top_p=0.8,
  frequency_penalty=0.0,
  presence_penalty=0.0#,
  #stop=["\n"]
)
