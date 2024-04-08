#!/bin/bash

source functions.sh

# API parameters
# Preferred model: gpt-4
OPENAI_API_MODEL="gpt-4"
# Endpoint changes may occur, check endpoint URL in OpenAI Platform
OPENAI_API_ENDPOINT="https://api.openai.com/v1/chat/completions"
# Insert you OpenAI API Key here (Safer if set as an environment variable)
OPENAI_API_KEY="sk-****************"

# Main function call
main
