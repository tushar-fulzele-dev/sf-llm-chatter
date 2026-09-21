# Multi-LLM Chat (Salesforce)

Personal multi-LLM chat inside Salesforce. Built step by step.

## Deploy (Step 2 foundation)
    sf org login web --alias chat-dev --set-default
    sf project deploy start --source-dir force-app --target-org chat-dev --dry-run
    sf project deploy start --source-dir force-app --target-org chat-dev
    sf org assign permset --name LLM_Chat_User --target-org chat-dev
    sf apex run --file scripts/apex/seed-settings.apex --target-org chat-dev

## Step 3: first connection
    # after creating EC_/NC_ in Setup and enabling the principal on the permission set:
    sf project deploy start --source-dir force-app/main/default/customMetadata --target-org chat-dev
    sf apex run --file scripts/apex/test-connection.apex --target-org chat-dev
    # persist the credential skeletons (check for secrets before committing!):
    sf project retrieve start --metadata ExternalCredential:EC_Gemini_Personal --metadata NamedCredential:NC_Gemini_Personal --metadata PermissionSet:LLM_Chat_User --target-org chat-dev

## Step 4: provider abstraction (Gemini first)
    sf project deploy start --source-dir force-app --target-org llmChatter
    sf apex run test --class-names GeminiProviderTest --class-names LlmProviderTest --code-coverage --result-format human --wait 10 --target-org llmChatter
    sf apex run --file scripts/apex/test-chat.apex --target-org llmChatter

## Step 4b: OpenAI and Claude adapters
    sf project deploy start --source-dir force-app --target-org llmChatter
    sf apex run test --class-names GeminiProviderTest --class-names OpenAiProviderTest --class-names ClaudeProviderTest --class-names LlmProviderTest --code-coverage --result-format human --wait 10 --target-org llmChatter
    # Per connection: create EC_/NC_ in Setup (tick "Allow Formulas in HTTP Header"), enable the principal on
    # LLM Chat User, copy its template from templates/connections/ into force-app/main/default/customMetadata/,
    # deploy, then edit connName/model in scripts/apex/test-chat.apex and run it.
