.386
.model flat, stdcall

.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
GetStdHandle PROTO, nStdHandle:DWORD
WriteConsoleA PROTO, hConsoleOutput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:PTR DWORD
ReadConsoleA PROTO, hConsoleInput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToRead:DWORD, lpNumberOfCharsRead:PTR DWORD, pInputControl:PTR DWORD
CreateFileA PROTO, lpFileName:PTR BYTE, dwDesiredAccess:DWORD, dwShareMode:DWORD, lpSecurityAttributes:DWORD, dwCreationDisposition:DWORD, dwFlagsAndAttributes:DWORD, hTemplateFile:DWORD
WriteFile PROTO, hFile:DWORD, lpBuffer:PTR BYTE, nNumberOfBytesToWrite:DWORD, lpNumberOfBytesWritten:PTR DWORD, lpOverlapped:PTR DWORD

.data

    hConsoleOut DWORD ?
    hConsoleIn DWORD ?
    userType BYTE 20 DUP(?)
    username BYTE 21 DUP(?)
    password BYTE 21 DUP(?)
    buffer BYTE 100 DUP(?)
    bytesWritten DWORD 0
    bytesRead DWORD 0
    hFile DWORD ?
    WELCOME_MSG DB "Welcome to McDonald's Food Ordering System", 13, 10, 0
    CHOICE_PROMPT DB "Select user type (1 for Customer, 2 for Staff): ", 0
    USERNAME_PROMPT DB "Enter username (max 20 chars): ", 0
    PASSWORD_PROMPT DB "Enter password (max 20 chars): ", 0
    SUCCESS_MSG DB "Registration successful! User data saved.", 13, 10, 0
    INVALID_CHOICE DB "Invalid choice. Please select 1 or 2.", 13, 10, 0
    FILENAME DB "users.txt", 0
    STD_OUTPUT_HANDLE EQU -11
    STD_INPUT_HANDLE EQU -10
    GENERIC_WRITE EQU 40000000h
    GENERIC_READ EQU 80000000h
    OPEN_ALWAYS EQU 4
    FILE_ATTRIBUTE_NORMAL EQU 80h
    CRLF DB 13, 10, 0

.code

main PROC
    ;first commit
    ; Get console handles
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsoleOut, eax
    INVOKE GetStdHandle, STD_INPUT_HANDLE
    mov hConsoleIn, eax

    ; Display welcome message
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET WELCOME_MSG, SIZEOF WELCOME_MSG - 1, OFFSET bytesWritten, 0

    ; Prompt for user type
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET CHOICE_PROMPT, SIZEOF CHOICE_PROMPT - 1, OFFSET bytesWritten, 0
    mov bytesRead, 0
    INVOKE ReadConsoleA, hConsoleIn, OFFSET userType, 20, OFFSET bytesRead, 0

    ; Validate user type (1 or 2)
    mov al, userType
    cmp al, '1'
    je customer
    cmp al, '2'
    je staff
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET INVALID_CHOICE, SIZEOF INVALID_CHOICE - 1, OFFSET bytesWritten, 0
    jmp exit_program

customer:
    mov BYTE PTR [userType], 'C'
    jmp get_user_info

staff:
    mov BYTE PTR [userType], 'S'

get_user_info:
    ; Prompt for username
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET USERNAME_PROMPT, SIZEOF USERNAME_PROMPT - 1, OFFSET bytesWritten, 0
    mov bytesRead, 0
    INVOKE ReadConsoleA, hConsoleIn, OFFSET username, 20, OFFSET bytesRead, 0
    ; Trim CRLF from username
    mov esi, OFFSET username
    mov ecx, bytesRead
    dec ecx
    cmp BYTE PTR [esi + ecx - 1], 10
    je trim_lf_username
    cmp BYTE PTR [esi + ecx - 1], 13
    je trim_cr_username
    jmp set_null_username
trim_lf_username:
    mov BYTE PTR [esi + ecx - 1], 0
    dec ecx
trim_cr_username:
    mov BYTE PTR [esi + ecx - 1], 0
set_null_username:
    mov BYTE PTR [esi + ecx], 0

    ; Prompt for password
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET PASSWORD_PROMPT, SIZEOF PASSWORD_PROMPT - 1, OFFSET bytesWritten, 0
    mov bytesRead, 0
    INVOKE ReadConsoleA, hConsoleIn, OFFSET password, 20, OFFSET bytesRead, 0
    ; Trim CRLF from password
    mov esi, OFFSET password
    mov ecx, bytesRead
    dec ecx
    cmp BYTE PTR [esi + ecx - 1], 10
    je trim_lf_password
    cmp BYTE PTR [esi + ecx - 1], 13
    je trim_cr_password
    jmp set_null_password
trim_lf_password:
    mov BYTE PTR [esi + ecx - 1], 0
    dec ecx
trim_cr_password:
    mov BYTE PTR [esi + ecx - 1], 0
set_null_password:
    mov BYTE PTR [esi + ecx], 0

    ; Open file to store user data
    INVOKE CreateFileA, OFFSET FILENAME, GENERIC_WRITE, 0, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    mov hFile, eax

    ; Prepare buffer: userType,username,password
    mov edi, OFFSET buffer
    mov al, userType
    mov [edi], al
    inc edi
    mov [edi], BYTE PTR ','
    inc edi

    mov esi, OFFSET username
    call copy_string
    mov [edi], BYTE PTR ','
    inc edi

    mov esi, OFFSET password
    call copy_string
    mov [edi], BYTE PTR 13
    inc edi
    mov [edi], BYTE PTR 10
    inc edi
    mov BYTE PTR [edi], 0

    ; Write to file
    INVOKE WriteFile, hFile, OFFSET buffer, edi, OFFSET bytesWritten, 0

    ; Display success message
    mov bytesWritten, 0
    INVOKE WriteConsoleA, hConsoleOut, OFFSET SUCCESS_MSG, SIZEOF SUCCESS_MSG - 1, OFFSET bytesWritten, 0

exit_program:
    ; Pause so console doesn't close
    mov bytesRead, 0
    INVOKE ReadConsoleA, hConsoleIn, OFFSET buffer, 1, OFFSET bytesRead, 0

    INVOKE ExitProcess, 0

copy_string PROC
    mov ecx, 20
copy_loop:
    mov al, [esi]
    cmp al, 0
    je copy_done
    mov [edi], al
    inc esi
    inc edi
    loop copy_loop
copy_done:
    ret
copy_string ENDP

main ENDP
END main