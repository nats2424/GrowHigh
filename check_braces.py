#!/usr/bin/env python3

def check_braces(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    level = 0
    line_num = 1
    
    for i, char in enumerate(content):
        if char == '\n':
            line_num += 1
        elif char == '{':
            level += 1
        elif char == '}':
            level -= 1
            if level < 0:
                print(f'ERROR: Extra closing brace at line {line_num}')
                return False
    
    if level != 0:
        print(f'ERROR: Unmatched braces. Final level: {level}')
        return False
    else:
        print('Braces are balanced')
        return True

if __name__ == "__main__":
    check_braces('/Users/hirasawamegumiyuu/growhigh/LevelUpTodo/Views/MainGameView.swift')