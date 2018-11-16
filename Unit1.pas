unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, GR32_Image,hsrv;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Button1: TButton;
    GroupBox2: TGroupBox;
    Memo1: TMemo;
    Image321: TImage32;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin

StartWebServer(strtoint(labelededit2.Text),labelededit1.text);
form1.memo1.lines.add('Server started on port : ' + labelededit2.Text);
end;



function ReadKey(RegKey:HKey; RegPath,Key:string): string;
var
 rk:hkey;
 size:LongWord;
 val:array[0..255] of char;
begin
 size := 256;
if RegOpenKey(RegKey,pchar(RegPath),rk) <> ERROR_SUCCESS then exit
else
 RegOpenKey(RegKey,pchar(RegPath),rk);
if RegQueryValueEx(rk,pchar(Key),Nil,Nil,@val,@size) = 0 then result := val;
 RegCloseKey(rk);
end;


function AppData : string;
const
   SHGFP_TYPE_CURRENT = 0;
var
   path: array [0..MAX_PATH] of char;
begin
Result:= Readkey(HKEY_CURRENT_USER,'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','AppData')+'\';
end;




procedure TForm1.FormCreate(Sender: TObject);
begin
appd:=AppData;
end;

end.
