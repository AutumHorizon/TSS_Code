$NewSecretValue = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})

# 65..90: ASCII values for uppercase letters (A-Z).
# 97..122: ASCII values for lowercase letters (a-z).
# 48..57: ASCII values for digits (0-9).

# Get-Random selects 16 random values from the combined list of ASCII codes.

# The % (alias for ForEach-Object) iterates through each randomly selected ASCII number.
# [char]$_ converts the ASCII number to its corresponding character.

# -join merges the randomly selected characters into a single string without spaces.

# You can extend the range to include symbols (!@#$%^&*() etc.) for stronger secrets: (33..126)

