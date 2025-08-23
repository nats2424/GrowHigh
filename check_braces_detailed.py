#!/usr/bin/env python3

def check_braces_detailed(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    level = 0
    
    for line_num, line in enumerate(lines, 1):
        for char in line:
            if char == '{':
                level += 1
                print(f'Line {line_num}: Opened brace (level {level}): {line.strip()}')
            elif char == '}':
                print(f'Line {line_num}: Closing brace (level {level}): {line.strip()}')
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
    check_braces_detailed('/Users/hirasawamegumiyuu/growhigh/LevelUpTodo/Views/MainGameView.swift')