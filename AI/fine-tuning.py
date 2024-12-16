from openai import OpenAI
client = OpenAI()

file = client.files.create(
file=open("training_data.jsonl", "rb"),
purpose="fine-tune"
)
client.fine_tuning.jobs.create(
training_file=file.id,
model="gpt-4o-2024-08-06"
)