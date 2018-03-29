unit TMSCG_All;
{=============================================================================
 TMSCG: The Most Stupid Computer Game

 Catch the quit-button to finish the game.
 I don't think, there is much description necessary, only this:
  - the button underlies virtual (mechanical) forces by window borders and
    mouse pointer;
  - The button moves according a simple implementation of Newtons law
  - Finishing the program by window command is only accepted after severalt
    tries, until then, (hopefully) encouraging random messages are shown.

 I don't know, if this ides was ever realized.
 The idea is too simple, to expect it as totally new. On the other hand:
 I did not see something stupid like this yet.

 I like the complex behavior of the game caused by a really simple principle
 and its implemetation.


=============================================================================}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    { Game target: This button has to be clicked }
    QuitBtn: TButton;
    { Dummy: This button just takes key pressing away from Quit Btn; To avoid
      closing by presing <RETURN> }
    BlindBtn: TButton;
    { periodic processing: ensures a "smooth" behaviour }
    Timer: TTimer;
    procedure ClickedBlind(Sender: TObject);
    procedure ClickedQuit(Sender: TObject);
    procedure CloseQry(Sender: TObject; var CanClose: boolean);
    procedure CreateQry(Sender: TObject);
    procedure MouseEnterEvent(Sender: TObject);
    procedure MouseLeaveEvent(Sender: TObject);
    procedure MouseMoveEvent(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure ResizeEvent(Sender: TObject);
    procedure TimerEvent(Sender: TObject);
  private
    BtnHit: boolean;
    MouseX, MouseY: longint;
    BtnCenterX, BtnCenterY: longint;
    BtnWidth, BtnHeight: longint;
    MinX, MaxX, MinY, MaxY: longint;
    DistX, DistY, DistSqr: double;
    Vx, Vy: double;
    RelX, RelY: double;
    Fx, Fy: double;
    CloseCnt: longint;
    MousePresentFlag: boolean;
    procedure SetBtnPos(var XCenter: longint; var YCenter: longint);
  public

  end;

var
  MainForm: TMainForm;

const
  { number of clicks to force closing window }
  CLOSEMAX = 6;
  { velocity decrease each time step }
  FRICTION_FAC = 0.95;
  { maximum force coming from window borders }
  BORDER_FMAX = 20;
  { maximum force coming from mouse }
  MOUSE_FMAX = 25;
  { maximum force in total }
  FMAX = 50;
  { button mass: decreases acceleration }
  BTN_MASS = 0.75;


implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.MouseMoveEvent(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  { Get current mouse pointer position }
  MouseX := X;
  MouseY := Y;
end;

procedure TMainForm.ResizeEvent(Sender: TObject);
begin
  { get new position constrains }
  MaxX := MainForm.Width - (BtnWidth div 2);
  MaxY := MainForm.Height - (BtnHeight div 2);

  { restore relative button position on window resizing }
  BtnCenterX := round(RelX * double(MainForm.Width));
  BtnCenterY := round(RelY * double(MainForm.Height));
  SetBtnPos(BtnCenterX, BtnCenterY);
end;

procedure TMainForm.TimerEvent(Sender: TObject);
begin
  { get forces from window borders }
  if (BtnCenterX > MinX) then
    Fx := BORDER_FMAX / (BtnCenterX - MinX)
  else
    Fx := BORDER_FMAX;

  if (BtnCenterX < MaxX) then
    Fx := Fx - BORDER_FMAX / (MaxX - BtnCenterX)
  else
    Fx := Fx - BORDER_FMAX;

  if (BtnCenterY > MinY) then
    Fy := BORDER_FMAX / (BtnCenterY - MinY)
  else
    Fy := BORDER_FMAX;

  if (BtnCenterY < MaxY) then
    Fy := Fy - BORDER_FMAX / (MaxY - BtnCenterY)
  else
    Fy := Fy - BORDER_FMAX;

  { get force from mouse pointer - only if mouse pointer is in window }
  if (MousePresentFlag = True) then
  begin
    DistX := double(MouseX - BtnCenterX);
    DistY := double(MouseY - BtnCenterY);
    DistSqr := DistX * DistX + DistY * DistY;

    { force is proportional to 1/distance, (btw: avoid division by zero }
    if (DistX <> 0) then
      Fx := Fx - MOUSE_FMAX * (DistX / DistSqr);
    if (DistY <> 0) then
      Fy := Fy - MOUSE_FMAX * (DistY / DistSqr);
  end;

  { limit total force }
  if (Fx > FMAX) then
    Fx := FMAX;
  if (Fx < -FMAX) then
    Fx := -FMAX;
  if (Fy > FMAX) then
    Fy := FMAX;
  if (Fy < -FMAX) then
    Fy := -FMAX;

  { calculate new velocity }
  Vx := FRICTION_FAC * Vx + Fx / BTN_MASS;
  Vy := FRICTION_FAC * Vy + Fy / BTN_MASS;

  { calculate new position }
  BtnCenterX := BtnCenterX + round(Vx);
  BtnCenterY := BtnCenterY + round(Vy);

  { adjust button at new position }
  SetBtnPos(BtnCenterX, BtnCenterY);

  { store relative button position - needed in case of window resizing }
  RelX := double(BtnCenterX) / double(MainForm.Width);
  RelY := double(BtnCenterY) / double(MainForm.Height);

  { force redraw of window }
  MainForm.Invalidate();
end;

procedure TMainForm.CloseQry(Sender: TObject; var CanClose: boolean);
begin
  { increase close request counter }
  CloseCnt := CloseCnt + 1;

  { if goal of the game was not met or close querys are too few:
    generate a random message - and reject closing}
  if ((BtnHit = False) and (CloseCnt < CLOSEMAX)) then
  begin
    CanClose := False;
    case (round(13 * random())) of
      0: ShowMessage('Not this way!');
      1: ShowMessage('Are you cheating?');
      2: ShowMessage('That´s too easy!');
      3: ShowMessage('Come on!');
      4: ShowMessage('You can do it!');
      5: ShowMessage('Don´t choose the emergency solution!');
      6: ShowMessage('Is this too challenging for you?');
      7: ShowMessage('You almost got it!');
      8: ShowMessage('Don´t give up!');
      9: ShowMessage('Just try!');
      10: ShowMessage('I do not accept that!');
      11: ShowMessage('That´s the greenhorn solution!');
      12: ShowMessage('More courage!');
      else
        ShowMessage('frustrated?');
    end;
  end
  else
  begin
    CanClose := True;
  end;
end;

procedure TMainForm.CreateQry(Sender: TObject);
begin

  { get button size - needed to be somewhat independend from IDE editing }
  BtnWidth := QuitBtn.Width;
  BtnHeight := QuitBtn.Height;

  { set button position constrains - related to center of button }
  MinX := BtnWidth div 2;
  MaxX := MainForm.Width - (BtnWidth div 2);
  MinY := BtnHeight div 2;
  MaxY := MainForm.Height - (BtnHeight div 2);

  { set button position to the center of window }
  BtnCenterX := MainForm.Width div 2;
  BtnCenterY := MainForm.Height div 2;

  { adjust button at new position }
  SetBtnPos(BtnCenterX, BtnCenterY);

  { store relative button position - needed in case of window resizing }
  RelX := double(BtnCenterX) / double(MainForm.Width);
  RelY := double(BtnCenterY) / double(MainForm.Height);

  { initialize button velocity }
  Vx := 0.0;
  Vy := 0.0;

  { initially expect mouse pointer outside window }
  MousePresentFlag := False;

  { initialize button hit state }
  BtnHit := False;

  { initialize close query counter }
  CloseCnt := 0;

  { initialize random generator }
  RandSeed := longint(round(double(Time) * 1000.0));
end;

procedure TMainForm.MouseEnterEvent(Sender: TObject);
begin
  { mouse is in window now}
  MousePresentFlag := True;
end;

procedure TMainForm.MouseLeaveEvent(Sender: TObject);
begin
  { mouse is not in window now}
  MousePresentFlag := False;
end;

procedure TMainForm.ClickedQuit(Sender: TObject);
begin
  { that's the goal }
  BtnHit := True;
  Close();
end;

procedure TMainForm.ClickedBlind(Sender: TObject);
begin
  { catch key pressed here - do nothing }
end;

procedure TMainForm.SetBtnPos(var XCenter: longint; var YCenter: longint);
begin
  { keep button inside window }
  if (XCenter < MinX) then
    XCenter := MinX;
  if (XCenter > MaxX) then
    XCenter := MaxX;

  if (YCenter < MinY) then
    YCenter := MinY;
  if (YCenter > MaxY) then
    YCenter := MaxY;

  { set button properties }
  QuitBtn.Left := XCenter - (BtnWidth div 2);
  QuitBtn.Top := YCenter - (BtnHeight div 2);
end;

end.







