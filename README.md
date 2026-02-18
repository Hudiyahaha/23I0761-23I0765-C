# Manual Lexical Scanner

A complete lexical scanner implementation in Java that tokenizes source code according to the language specification.

## Project Structure

- `TokenType.java` - Enumeration of all token types
- `Token.java` - Token data class (type, lexeme, line, column)
- `SymbolTable.java` - Tracks identifiers and their usage
- `ErrorHandler.java` - Collects and reports lexical errors
- `ManualScanner.java` - Main scanner implementation
- `ScannerMain.java` - Entry point to run the scanner

## Features

- **Token Recognition**: Identifies keywords, identifiers, literals (integer, float, string, char), operators, and punctuators
- **Comment Handling**: Removes single-line (`##`) and multi-line (`#* ... *#`) comments
- **Symbol Table**: Tracks all identifiers with first occurrence location and frequency
- **Error Recovery**: Continues scanning after errors, collecting all issues
- **Statistics**: Reports token counts and scanner statistics

## Compilation

```bash
javac *.java
```

## Usage

```bash
java ScannerMain <input_file>
```

Example:
```bash
java ScannerMain test.txt
```

## Output

The scanner produces:
1. **Tokens**: List of all recognized tokens with their type, lexeme, line, and column
2. **Statistics**: Token counts by type and comments removed
3. **Symbol Table**: All identifiers found in the code
4. **Errors**: Any lexical errors encountered (if any)

## Language Rules

- **Identifiers**: Must start with uppercase letter [A-Z], max 31 characters
- **Keywords**: `start`, `finish`, `loop`, `condition`, `declare`, `output`, `input`, `function`, `return`, `break`, `continue`, `else`
- **Comments**: 
  - Single-line: `##` to end of line
  - Multi-line: `#* ... *#`
- **Operators**: Arithmetic (`+`, `-`, `*`, `/`, `%`, `**`), Relational (`==`, `!=`, `<=`, `>=`, `<`, `>`), Logical (`&&`, `||`, `!`), Assignment (`=`, `+=`, `-=`, `*=`, `/=`), Increment/Decrement (`++`, `--`)
- **Literals**: Integer, Float (with decimal or exponent), String (`"..."`), Char (`'.'`)
