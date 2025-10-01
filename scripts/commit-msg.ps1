#!/usr/bin/env pwsh

function New-ClaudeCommitMessage {
    param()
    # Get staged diff
    $diff = git diff --cached

    if ([string]::IsNullOrWhiteSpace($diff)) {
        Write-Host "No staged changes found. Stage your changes first with 'git add'."
        exit 1
    }

    # Create commit message using Claude
    $prompt = @"
Follow the Conventional Commits format strictly for commit messages. Use the structure below:

``````
<type>[optional scope]: <gitmoji> <description>

[optional body]
``````

Guidelines:

1. **Type and Scope**: Choose an appropriate type (e.g., ``feat``, ``fix``) and optional scope to describe the affected module or feature.

2. **Gitmoji**: Include a relevant ``gitmoji`` that best represents the nature of the change.

3. **Description**: Write a concise, informative description in the header; use backticks if referencing code or specific terms.

4. **Body**: For additional details, use a well-structured body section:
   - Use bullet points (``*``) for clarity.
   - Clearly describe the motivation, context, or technical details behind the change, if applicable.

Commit messages should be clear, informative, and professional, aiding readability and project tracking.

Here are my staged changes:

$diff

Generate only the commit message, nothing else.
"@

    # Generate commit message
    $commitMsg = claude -p $prompt

    Write-Host "Generated Commit Message:`n$commitMsg" -ForegroundColor Green

    $choice = Read-Host 'Use this commit message? (y/n/e to edit)'

    switch ($choice.ToLower()) {
        'y' {
            git commit -m $commitMsg
        }
        'e' {
            git commit -e -m $commitMsg
        }
        default {
            Write-Host 'Commit cancelled.' -ForegroundColor Yellow
            exit 1
        }
    }
}
