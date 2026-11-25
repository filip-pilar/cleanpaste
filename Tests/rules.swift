// Test helper: prints each argument cleaned. Built with Cleaner.swift and Rules.swift.
for url in CommandLine.arguments.dropFirst() { print(cleanURL(url) ?? url) }
