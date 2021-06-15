; Листинг 2.3.3. Пример обработки событий от мыши и клавиатуры для консольного приложения

.586P 
;плоская модель памяти 
.MODEL FLAT, stdcall 
;константы 
STD_OUTPUT_HANDLE  equ -11 
STD_INPUT_HANDLE   equ -10 
;тип события 
KEY_EV             equ 1h 
MOUSE_EV           equ 2h 
;константы - состояния клавиатуры 
RIGHT_ALT_PRESSED  equ 1h 
LEFT_ALT_PRESSED   equ 2h 
RIGHT_CTRL_PRESSED equ 4h 
LEFT_CTRL_PRESSED  equ 8h 
SHIFT_PRESSED      equ 10h 
NUMLOCK_ON         equ 20h 
SCROLLLOCK_ON      equ 40h 
CAPSLOCK_ON        equ 80h 
ENHANCED_KEY       equ 100h 
;прототипы внешних процедур 
EXTERN  wsprintfA:NEAR 
EXTERN  GetStdHandle@4:NEAR 
EXTERN  WriteConsoleA@20:NEAR 
EXTERN  SetConsoleCursorPosition@8:NEAR 
EXTERN  SetConsoleTitleA@4:NEAR 
EXTERN  FreeConsole@0:NEAR 
EXTERN  AllocConsole@0:NEAR 
EXTERN  CharToOemA@8:NEAR 
EXTERN  SetConsoleTextAttribute@8:NEAR
EXTERN  ReadConsoleInputA@16:NEAR 
EXTERN  ExitProcess@4:NEAR 
 
;директивы компоновщику для подключения библиотек 
includelib c:\masm32\lib\user32.lib 
includelib c:\masm32\lib\kernel32.lib 
;------------------------------------------ 
;структура для определения событий 
COOR  STRUC 
X  WORD ? 
Y  WORD ? 
COOR  ENDS 
;сегмент данных 
_DATA SEGMENT 
      STR1   DB "Для выхода нажмите ESC",0 
      STR2   DB "Обработка событий мыши",0 
      HANDL  DWORD ? 
      HANDL1 DWORD ? 
      BUF    DB 200 dup(?) 
      LENS   DWORD ? ;количество выведенных символов 
      CO     DWORD ? 
      FORM   DB "Координаты: %u %u " 
      CRD    COOR <?> 
      MOUS_KEY WORD 9 dup(?) 
_DATA ENDS 
;сегмент кода 
_TEXT SEGMENT 
START: 
;перекодировка строк 
PUSH OFFSET STR2 
PUSH OFFSET STR2 
CALL CharToOemA@8 
PUSH OFFSET STR1 
PUSH OFFSET STR1 
CALL CharToOemA@8 
;образовать консоль 
;вначале освободить уже существующую 
CALL FreeConsole@0 
CALL AllocConsole@0 
;получить HANDL1 ввода 
PUSH STD_INPUT_HANDLE 
CALL GetStdHandle@4 
MOV  HANDL1,EAX 
;получить HANDL вывода 
PUSH STD_OUTPUT_HANDLE 

CALL GetStdHandle@4 
MOV  HANDL,EAX 
;задать заголовок окна консоли 
PUSH OFFSET STR2 
CALL SetConsoleTitleA@4 
;длина строки 
PUSH OFFSET STR1 
CALL LENSTR 
;вывести строку 
PUSH 0 
PUSH OFFSET LENS 
PUSH EBX 
PUSH OFFSET STR1 
PUSH HANDL 
CALL WriteConsoleA@20 
;цикл ожиданий: движение мыши или двойной щелчок 
LOO: 
;координаты курсора 
MOV CRD.X,0 
MOV CRD.Y,10 
PUSH CRD 
PUSH HANDL 
CALL SetConsoleCursorPosition@8 
;прочитать одну запись о событии 
PUSH OFFSET CO 
PUSH 1 
PUSH OFFSET MOUS_KEY 
PUSH HANDL1 
CALL ReadConsoleInputA@16 
;проверим, не с мышью ли что? 
CMP WORD PTR MOUS_KEY,MOUSE_EV 
JNE LOO1 
;здесь преобразуем координаты мыши в строку 
MOV AX,WORD PTR MOUS_KEY+6 ;Y-координата курсора мыши 
;копирование с обнулением старших битов 
MOVZX EAX,AX 
PUSH  EAX 
MOV   AX,WORD PTR MOUS_KEY+4 ;X-координата курсора мыши 
;копирование с обнулением старших битов 
MOVZX EAX,AX 
PUSH EAX 
PUSH OFFSET FORM 
PUSH OFFSET BUF 
CALL wsprintfA 
;восстановить стек 
ADD ESP,16 
;перекодировать строку для вывода 
PUSH OFFSET BUF 
PUSH OFFSET BUF 
CALL CharToOemA@8 
;длина строки 
PUSH OFFSET BUF 
CALL LENSTR 
;вывести на экран координаты курсора 
PUSH 0 
PUSH OFFSET LENS 
PUSH EBX 
PUSH OFFSET BUF 
PUSH HANDL 
CALL WriteConsoleA@20 
JMP  LOO ;к началу цикла 
LOO1: 
;нет ли события от клавиатуры? 
CMP WORD PTR MOUS_KEY,KEY_EV 
JNE LOO 
;есть, какое? 
CMP BYTE PTR MOUS_KEY+14,27 
JNE LOO 
;****************************** 
;закрыть консоль 
CALL FreeConsole@0 
PUSH 0 
CALL ExitProcess@4 
RET 
;процедура определения длины строки 
;строка - [EBP+08H] 
;длина в EBX 
LENSTR PROC 
      ENTER 0,0 
      PUSH  EAX 
      PUSH  EDI 
      CLD 
      MOV   EDI,DWORD PTR [EBP+08H] 
      MOV   EBX,EDI 
      MOV   ECX,100   ; ограничить длину строки 
      XOR   AL,AL 
      REPNE SCASB     ; найти символ 0 
      SUB   EDI,EBX   ; длина строки, включая 0 
      MOV   EBX,EDI 
      DEC   EBX 
      POP   EDI 
      POP   EAX 
      LEAVE 
      RET   4 
LENSTR ENDP 
_TEXT ENDS 
END START 


; ------------------------------------------------------------------------
;Трансляция программы из листинга 2.3.3: 
;ml /c /coff cons3.asm 
;link /subsystem:console cons3.obj 
; ------------------------------------------------------------------------

;После того как вы познакомились с программой из листинга 2.3.3, давайте ее 
;подробнее обсудим. 
;Начнем с функции wsprintfA. Как я уже заметил, эта функция необычная. Во-
;первых, она имеет переменное число параметров. Первые два параметра обя-
;зательны. Вначале идет указатель на буфер, куда будет скопирована резуль-
;тирующая строка. Вторым идет указатель на форматную строку. Форматная 
;строка может содержать текст, а также собственно формат выводимых пара-
;метров. Поля, содержащие информацию о параметре, начинаются с символа %. 
;Формат этих полей в точности соответствует формату полей, используемых  
;в стандартных С-функциях printf,  sprintf и др. Исключением является от-
;сутствие в формате для функции wsprintfA вещественных чисел. Нет нужды 
;рассматривать этот формат подробно, замечу только, что каждое поле в фор-
;матной строке соответствует параметру (начиная с третьего). В нашем случае 
;форматная строка была равна: "Координаты: %u %u". Это означало, что далее  
;в стек будут отправлены два числовых параметра типа WORD. Конечно, в стек 
;мы отправили два двойных слова, позаботившись лишь о том, чтобы старшие 
;слова были обнулены. Для такой операции очень удобна команда микропро-
;цессора MOVZX, которая копирует второй операнд в первый так, чтобы биты 
;старшего слова были заполнены нулями. Если бы параметры были двойными 
;словами, то вместо поля %u мы бы поставили %lu. В случае, если поле фор-
;матной строки определяет строку-параметр, например "%S", в стек следует 
;отправлять указатель на строку (что естественно).2 
;Во-вторых, поскольку функция "не знает", сколько параметров может быть  
;в нее отправлено, разработчики не стали усложнять текст этой функции  
;и оставили нам задачу освобождения стека.3 Стек освобождается командой 
;ADD ESP,N. Здесь N — это количество освобождаемых байтов.
;
;Обратимся теперь к функции ReadConsoleInputA. К уже сказанному о ней до-
;бавлю только то, что если буфер событий пуст, то функция будет ждать, пока 
;"что-то" не случится с консольным окном, и только тогда возвратит управле-
;ние. Кроме того, мы можем указать, чтобы функция возвращала не одну,  
;а несколько записей о происшедших с консолью событиях. В этом случае  
;в буфер будет помещена не одна, а несколько информационных записей.  
;Но мы на этом останавливаться не будем. 
;В приложении 6 и на прилагаемом к книге компакт-диске содержится кон-
;сольная программа с обработкой всевозможных событий от клавиатуры  
;и мыши. Советую разобрать структуру и функционирование этой поучитель-
;ной программы. 
;
;
;В этой связи не могу не отметить, что встречал в литературе по ассемблеру (!) ут-
;верждение, что все помещаемые в стек для этой функции параметры являются указа-
;телями. Как видим, вообще говоря, это не верно.  
;Компилятор С, естественно, делает это за нас.