unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, XMLIntf, XMLDoc, Global, IniFiles, uIMDownloader;

type
  TMainForm = class(TForm)
    GBUpdater: TGroupBox;
    ProgressBarDownloads: TProgressBar;
    LAmountDesc: TLabel;
    LAmount: TLabel;
    LSpeedDesc: TLabel;
    LSpeed: TLabel;
    ButtonSettings: TButton;
    ButtonUpdate: TButton;
    SettingsPageControl: TPageControl;
    TabSheetConnectSettings: TTabSheet;
    TabSheetLog: TTabSheet;
    GBConnectSettings: TGroupBox;
    LProxyAddress: TLabel;
    LProxyPort: TLabel;
    LProxyUser: TLabel;
    LProxyUserPasswd: TLabel;
    CBUseProxy: TCheckBox;
    EProxyAddress: TEdit;
    EProxyPort: TEdit;
    EProxyUser: TEdit;
    CBProxyAuth: TCheckBox;
    EProxyUserPasswd: TEdit;
    LogMemo: TMemo;
    LFileDesc: TLabel;
    LFileDescription: TLabel;
    LFileMD5Desc: TLabel;
    LFileMD5: TLabel;
    LFileNameDesc: TLabel;
    LFileName: TLabel;
    IMDownloader1: TIMDownloader;
    LStatus: TLabel;
    TabSheetSettings: TTabSheet;
    GBSettings: TGroupBox;
    LLanguage: TLabel;
    CBLang: TComboBox;
    LIMClientType: TLabel;
    CBIMClientType: TComboBox;
    LDBType: TLabel;
    CBDBType: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonSettingsClick(Sender: TObject);
    procedure ButtonUpdateStartClick(Sender: TObject);
    procedure ButtonUpdateStopClick(Sender: TObject);
    procedure CBUseProxyClick(Sender: TObject);
    procedure CBProxyAuthClick(Sender: TObject);
    procedure IMDownloader1StartDownload(Sender: TObject);
    procedure IMDownloader1Break(Sender: TObject);
    procedure IMDownloader1Downloading(Sender: TObject; AcceptedSize, MaxSize: Cardinal);
    procedure IMDownloader1Error(Sender: TObject; E: TIMDownloadError);
    procedure IMDownloader1Accepted(Sender: TObject);
    procedure IMDownloader1Headers(Sender: TObject; Headers: String);
    procedure IMDownloader1MD5Checked(Sender: TObject; MD5Correct, SizeCorrect: Boolean; MD5Str: string);
    procedure CBLangChange(Sender: TObject);
    procedure CBIMClientTypeChange(Sender: TObject);
    procedure CBDBTypeChange(Sender: TObject);
    procedure ButtonUpdateEnableStart;
    procedure ButtonUpdateEnableStop;
    procedure FindLangFile;
    procedure CoreLanguageChanged;
    procedure InstallUpdate;
    procedure SetProxySettings;
    function  StartStepByStepUpdate(CurrStep: Integer; INIFileName: String): Integer;
  private
    { Private declarations }
    FLanguage : WideString;
    // ��� �������������� ���������
    procedure OnLanguageChanged(var Msg: TMessage); message WM_LANGUAGECHANGED;
    procedure LoadLanguageStrings;
    function EndTask(TaskName, FormName: String): Boolean;
  public
    { Public declarations }
    RunAppDone: Boolean;
    C1, C2: TLargeInteger;
    iCounterPerSec: TLargeInteger;
    TrueHeader: Boolean;
    CurrentUpdateStep: Integer;
    HeaderMD5: String;
    HeaderFileSize: Integer;
    HeaderFileName: String;
    MD5InMemory: String;
    IMMD5Correct: Boolean;
    IMSizeCorrect: Boolean;
    INISavePath: String;
    property CoreLanguage: WideString read FLanguage;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // ���������� ��� ������ ����-����
  Global_MainForm_Showing := False;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  CmdHelpStr: WideString;
begin
  RunAppDone := False;
  TrueHeader := False;
  IMMD5Correct := False;
  IMSizeCorrect := False;
  CurrentUpdateStep := 0;
  // ��������� �� ���������� �������
  if GetSysLang = '�������' then
  begin
    CmdHelpStr := '��������� ������� ' + ProgramsName + ' v' + ProgramsVer + ':' + #13 +
    '--------------------------------------------------------------' + #13#13 +
    'HistoryToDBUpdater.exe <1>' + #13#13 +
    '<1> - (�������������� ��������) - ���� �� ����� �������� HistoryToDB.ini (��������: "C:\Program Files\QIP Infium\Profiles\username@qip.ru\Plugins\QIPHistoryToDB\")';
  end
  else
  begin
    CmdHelpStr := 'Startup options ' + ProgramsName + ' v' + ProgramsVer + ':' + #13 +
    '------------------------------------------------' + #13#13 +
    'HistoryToDBUpdater.exe <1>' + #13#13 +
    '<1> - (Optional) - The path to the configuration file HistoryToDB.ini (Example: "C:\Program Files\QIP Infium\Profiles\username@qip.ru\Plugins\QIPHistoryToDB\")';
  end;
  // �������� ������� ����������
  if (ParamStr(1) = '/?') or (ParamStr(1) = '-?') then
  begin
    MsgInf(ProgramsName, CmdHelpStr);
    Exit;
  end
  else
  begin
    if ParamCount >= 1 then
    begin
      ProfilePath := ParamStr(1);
    end
    else
    begin
      ProfilePath := ExtractFilePath(Application.ExeName);
    end;
    PluginPath := ExtractFilePath(Application.ExeName);
    INISavePath := ExtractFilePath(Application.ExeName)+'HistoryToDBUpdate.ini';
    IMDownloader1.DirPath := PluginPath;
    // ������������� �����������
    EncryptInit;
    // ������ ���������
    LoadINI(ProfilePath, false);
    // ��������� ��������� �����������
    if ParamCount >= 1 then
      FLanguage := DefaultLanguage
    else
    begin
      if GetSysLang = '�������' then
        FLanguage := 'Russian'
      else
        FLanguage := 'English';
    end;
    LangDoc := NewXMLDocument();
    if not DirectoryExists(PluginPath + dirLangs) then
      CreateDir(PluginPath + dirLangs);
    if not FileExists(PluginPath + dirLangs + defaultLangFile) then
    begin
      if GetSysLang = '�������' then
        CmdHelpStr := '���� ����������� ' + PluginPath + dirLangs + defaultLangFile + ' �� ������.'
      else
        CmdHelpStr := 'The localization file ' + PluginPath + dirLangs + defaultLangFile + ' is not found.';
      MsgInf(ProgramsName, CmdHelpStr);
      // ����������� �������
      EncryptFree;
      Exit;
    end;
    CoreLanguageChanged;
    // ��������� ������ ������
    FindLangFile;
    // ��� �������������� ���������
    MainFormHandle := Handle;
    SetWindowLong(Handle, GWL_HWNDPARENT, 0);
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_APPWINDOW);
    // ��������� ���� ����������
    LoadLanguageStrings;
    // ��������� ��������
    RunAppDone := True;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if RunAppDone then
  begin
    // ����������� �������
    EncryptFree;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  // ���������� ��� ������ ����-����
  Global_MainForm_Showing := True;
  // ������������ ����
  AlphaBlend := AlphaBlendEnable;
  AlphaBlendValue := AlphaBlendEnableValue;
  // ��. ���������
  LAmount.Caption := '0 �����';
  LFileName.Caption := '�� ��������';
  LFileDescription.Caption := '�� ��������';
  LFileMD5.Caption := '�� ��������';
  LSpeed.Caption := '0 �����/���';
  CBUseProxy.Checked := False;
  EProxyAddress.Enabled := False;
  EProxyPort.Enabled := False;
  CBProxyAuth.Enabled := False;
  SettingsPageControl.ActivePage := TabSheetSettings;
  SettingsPageControl.Visible := False;
  MainForm.Height := SettingsPageControl.Height + 5;
  if DBType = 'Unknown' then
  begin
    CBDBType.Enabled := True;
    CBDBType.Items.Add('Unknown');
    CBDBType.Items.Add('mysql');
    CBDBType.Items.Add('postgresql');
    CBDBType.Items.Add('oracle');
    CBDBType.Items.Add('sqlite-3');
    CBDBType.Items.Add('firebird-2.0');
    CBDBType.Items.Add('firebird-2.5');
    CBDBType.ItemIndex := 0;
    // ���������� ���������
    ButtonSettingsClick(Self);
  end
  else
  begin
    CBDBType.Enabled := False;
    CBDBType.Items.Add(DBType);
    CBDBType.ItemIndex := 0;
  end;
  if IMClientType = 'Unknown' then
  begin
    CBIMClientType.Enabled := True;
    CBIMClientType.Items.Add('Unknown');
    CBIMClientType.Items.Add('QIP');
    CBIMClientType.Items.Add('RnQ');
    CBIMClientType.Items.Add('Skype');
    CBIMClientType.Items.Add('Miranda');
    CBIMClientType.ItemIndex := 0;
    // ���������� ��������� ���� �� ���� �������� �����
    if not SettingsPageControl.Visible then
      ButtonSettingsClick(Self);
  end
  else
  begin
    CBIMClientType.Enabled := False;
    CBIMClientType.Items.Add(IMClientType);
    CBIMClientType.ItemIndex := 0;
  end;
end;

procedure TMainForm.ButtonSettingsClick(Sender: TObject);
begin
  if not SettingsPageControl.Visible then
  begin
    MainForm.Height := GBUpdater.Height + SettingsPageControl.Height + 55;
    SettingsPageControl.Visible := True;
  end
  else
  begin
    SettingsPageControl.Visible := False;
    MainForm.Height := SettingsPageControl.Height + 5;
  end;
end;

procedure TMainForm.ButtonUpdateStartClick(Sender: TObject);
var
  AllProcessEndErr: Integer;
begin
  AllProcessEndErr := 0;
  if (DBType = 'Unknown') or (IMClientType  = 'Unknown') then
    MsgInf(Caption, GetLangStr('SelectDBTypeAndIMClient'))
  else
  begin
    LogMemo.Clear;
    // ���� ���������� ���������� ������� � ��������� ��
    if not EndTask('HistoryToDBSync.exe', 'HistoryToDBSync for ' + IMClientType) then
      Inc(AllProcessEndErr);
    if not EndTask('HistoryToDBViewer.exe', 'HistoryToDBViewer for ' + IMClientType) then
      Inc(AllProcessEndErr);
    if not EndTask('HistoryToDBImport.exe', 'HistoryToDBImport for ' + IMClientType) then
      Inc(AllProcessEndErr);
    // ���� ��� �������� �����, �� �����������
    if AllProcessEndErr = 0 then
    begin
      // ���� IM-������ � ��������� ���
      if IMClientType = 'QIP' then
        EnumWindows(@ProcCloseEnum, GetProcessID('qip.exe'));
      if IMClientType = 'Miranda' then
        EnumWindows(@ProcCloseEnum, GetProcessID('miranda32.exe'));
      if IMClientType = 'RnQ' then
        EnumWindows(@ProcCloseEnum, GetProcessID('rnq.exe'));
      if IMClientType = 'Skype' then
        EnumWindows(@ProcCloseEnum, GetProcessID('skype.exe'));
      // �������� ����������
      TrueHeader := False;
      CurrentUpdateStep := 0;
      SetProxySettings;
      IMDownloader1.URL := uURL;
      IMDownloader1.DownLoad;
    end
    else
      MsgInf(Caption, '��������� ������ ���� ����������� ������� ������� � ���������� ��������� ����������.');
  end;
end;

{ ������������� ��������� ������ }
procedure TMainForm.SetProxySettings;
begin
  if CBUseProxy.Checked then
  begin
    IMDownloader1.Proxy := EProxyAddress.Text + ':' + EProxyPort.Text;
    if CBProxyAuth.Checked then
    begin
      IMDownloader1.AuthUserName := EProxyUser.Text;
      IMDownloader1.AuthPassword := EProxyUserPasswd.Text;
    end
    else
    begin
      IMDownloader1.AuthUserName := '';
      IMDownloader1.AuthPassword := '';
    end;
  end
  else
  begin
    IMDownloader1.Proxy := '';
    IMDownloader1.AuthUserName := '';
    IMDownloader1.AuthPassword := '';
  end;
end;

procedure TMainForm.IMDownloader1Accepted(Sender: TObject);
var
  SavePath: String;
  MaxSteps: Integer;
begin
  LStatus.Caption := '���������� ������� ���������.';
  LStatus.Repaint;
  LAmount.Caption := CurrToStr(IMDownloader1.AcceptedSize/1024)+' �����';
  LAmount.Repaint;
  if not TrueHeader then
  begin
    LFileName.Caption := '�� ��������';
    LFileDescription.Caption := '�� ��������';
    LFileMD5.Caption := '�� ��������';
    LStatus.Caption := '������������ ��������� ������ � �������.';
  end
  else
  begin
    LStatus.Caption := '������� ����������� ����� �����...';
    LStatus.Repaint;
    if MD5InMemory <> 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' then
    begin
      LogMemo.Lines.Add('MD5 ����� � ������: ' + MD5InMemory);
      LogMemo.Lines.Add('������ ����� � ������: ' + IntToStr(IMDownloader1.OutStream.Size));
    end;
    if IMMD5Correct and IMSizeCorrect then
    begin
      if MD5InMemory <> 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' then
      begin
        LStatus.Caption := '����������� ����� � ������ ����� ������������.';
        LStatus.Repaint;
        LogMemo.Lines.Add('����������� ����� � ������ ����� ������������.');
      end
      else
      begin
        LStatus.Caption := '����������� ����� ����� �� ����� � �� ������� ���������.';
        LStatus.Repaint;
        LogMemo.Lines.Add('����������� ����� ����� �� ����� � �� ������� ���������.');
      end;
      // ���� ������ ��� - ���������� INI �����
      if CurrentUpdateStep = 0 then
      begin
        SavePath := ExtractFilePath(Application.ExeName);
        INISavePath := ExtractFilePath(Application.ExeName)+HeaderFileName;
      end
      else
        SavePath := ExtractFilePath(Application.ExeName)+'temp\';
      // ��������� ������� ��� ����������
      if not DirectoryExists(SavePath) then
        CreateDir(SavePath);
      // ������� ������ ����
      if FileExists(SavePath + HeaderFileName) then
        DeleteFile(SavePath + HeaderFileName);
      // ��������� �����
      try
        if MD5InMemory <> 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' then
        begin
          IMDownloader1.OutStream.SaveToFile(SavePath + HeaderFileName);
          LStatus.Caption := '���� �������� ��� ������ ' + HeaderFileName;
          LStatus.Repaint;
          LogMemo.Lines.Add('���� �������� ��� ������ ' + HeaderFileName);
        end;
        Inc(CurrentUpdateStep);
        if CurrentUpdateStep > 0 then
          MaxSteps := StartStepByStepUpdate(CurrentUpdateStep, INISavePath);
      except
        on E: Exception do
        begin
          LStatus.Caption := '������ ���������� ����� ' + HeaderFileName;
          LStatus.Repaint;
          LogMemo.Lines.Add('������ ���������� ����� ' + HeaderFileName);
        end;
      end;
    end
    else
    begin
      if not IMMD5Correct then
      begin
        LStatus.Caption := '�� �������� ����������� ����� �������� ������.';
        LStatus.Repaint;
        LogMemo.Lines.Add('�� �������� ����������� ����� �������� ������.');
      end;
      if not IMSizeCorrect then
      begin
        LStatus.Caption := '�� �������� ������ �������� ������.';
        LStatus.Repaint;
        LogMemo.Lines.Add('�� �������� ������ �������� ������.');
      end;
      ButtonUpdateEnableStart;
    end;
  end;
end;

function TMainForm.StartStepByStepUpdate(CurrStep: Integer; INIFileName: String): Integer;
var
  UpdateINI: TIniFile;
  MaxStep, IMClientCount, IMClientDownloadFileCount: Integer;
  DatabaseCount, DatabaseDownloadFileCount, I: Integer;
  IMClientName, IMClientNum, UpdateURL: String;
  DatabaseName, DatabaseNum: String;
  FileListArray: TArrayOfString;
  DownloadListArray: TArrayOfString;
begin
  Result := 0;
  if FileExists(INIFileName) then
  begin
    UpdateINI := TIniFile.Create(INIFileName);
    MaxStep := UpdateINI.ReadInteger('HistoryToDBUpdate', 'FileCount', 0);
    IMClientCount := UpdateINI.ReadInteger('HistoryToDBUpdate', 'IMClientCount', 0);
    LogMemo.Lines.Add('����� IM-�������� � INI-����� = ' + IntToStr(IMClientCount));
    IMClientDownloadFileCount := 0;
    SetLength(DownloadListArray, 0);
    if IMClientCount > 0 then
    begin
      IMClientName := '';
      while (IMClientCount > 0) and (IMClientName <> CBIMClientType.Items[CBIMClientType.ItemIndex]) do
      begin
        IMClientName := UpdateINI.ReadString('HistoryToDBUpdate', 'IMClient'+IntToStr(IMClientCount)+'Name', '');
        IMClientNum := UpdateINI.ReadString('HistoryToDBUpdate', 'IMClient'+IntToStr(IMClientCount)+'File', '');
        if EnableDebug then
        begin
          LogMemo.Lines.Add('IM-������ = ' + IMClientName);
          LogMemo.Lines.Add('������ ������ = ' + IMClientNum);
        end;
        Dec(IMClientCount);
      end;
      FileListArray := StringToParts(IMClientNum, [',']);
      SetLength(DownloadListArray, Length(FileListArray));
      DownloadListArray := FileListArray;
      IMClientDownloadFileCount := Length(FileListArray);
      if EnableDebug then
      begin
        for I := 0 to High(FileListArray) do
          LogMemo.Lines.Add('� ����� ��� '+IMClientName+' = ' + FileListArray[I]);
      end;
    end;
    DatabaseCount := UpdateINI.ReadInteger('HistoryToDBUpdate', 'DatabaseCount', 0);
    DatabaseDownloadFileCount := 0;
    LogMemo.Lines.Add('����� ����� Database � INI-����� = ' + IntToStr(DatabaseCount));
    if DatabaseCount > 0 then
    begin
      DatabaseName := '';
      while (DatabaseCount > 0) and (DatabaseName <> CBDBType.Items[CBDBType.ItemIndex]) do
      begin
        DatabaseName := UpdateINI.ReadString('HistoryToDBUpdate', 'Database'+IntToStr(DatabaseCount)+'Name', '');
        DatabaseNum := UpdateINI.ReadString('HistoryToDBUpdate', 'Database'+IntToStr(DatabaseCount)+'File', '');
        if EnableDebug then
        begin
          LogMemo.Lines.Add('Database = ' + DatabaseName);
          LogMemo.Lines.Add('������ ������ = ' + DatabaseNum);
        end;
        Dec(DatabaseCount);
      end;
      FileListArray := StringToParts(DatabaseNum, [',']);
      SetLength(DownloadListArray, Length(DownloadListArray) + Length(FileListArray));
      DatabaseDownloadFileCount := Length(FileListArray);
      for I := 0 to High(FileListArray) do
      begin
        DownloadListArray[IMClientDownloadFileCount+I] := FileListArray[I];
        if EnableDebug then
          LogMemo.Lines.Add('� ����� ��� '+DatabaseName+' = ' + FileListArray[I]);
      end;
    end;
    if EnableDebug then
    begin
      LogMemo.Lines.Add('����� ����� = ' + IntToStr(Length(DownloadListArray)));
      for I := 0 to High(DownloadListArray) do
        LogMemo.Lines.Add('DownloadListArray['+IntToStr(I)+'] = ' + DownloadListArray[I]);
    end;
    MaxStep := IMClientDownloadFileCount + DatabaseDownloadFileCount;
    Result := MaxStep;
    if EnableDebug then
      LogMemo.Lines.Add('����� ����� = ' + IntToStr(MaxStep));
    if CurrentUpdateStep > MaxStep then
    begin
      LStatus.Caption := '��� ���������� ������� ���������.';
      LStatus.Repaint;
      LogMemo.Lines.Add('=========================================');
      LogMemo.Lines.Add('��� ���������� ������� ���������.');
      InstallUpdate;
      LStatus.Caption := '��� ���������� ������� �����������.';
      LStatus.Repaint;
      LogMemo.Lines.Add('=========================================');
      LogMemo.Lines.Add('��� ���������� ������� �����������.');
      ButtonUpdateEnableStart;
      Exit;
    end;
    LogMemo.Lines.Add('================= ��� '+IntToStr(CurrStep)+' =================');
    LogMemo.Lines.Add('����� ������ ��� ���������� = ' + IntToStr(MaxStep));
    if MaxStep > 0 then
    begin
      UpdateURL := UpdateINI.ReadString('HistoryToDBUpdate', 'File'+DownloadListArray[CurrStep-1], '');
      if (UpdateURL <> '') and (CurrStep <= MaxStep) then
      begin
        LogMemo.Lines.Add('��������� ���� ��� ���������� = ' + UpdateURL);
        IMDownloader1.URL := UpdateURL;
        IMDownloader1.DownLoad;
      end
      else
        CurrentUpdateStep := 0;
    end;
  end
  else
    LogMemo.Lines.Add('�� ������ ���� �������� ���������� ' + INIFileName);
end;

procedure TMainForm.InstallUpdate;
var
  SR: TSearchRec;
  I: Integer;
begin
  if FindFirst(PluginPath + 'temp' + '\*.*', faAnyFile or faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr = faDirectory) and ((SR.Name = '.') or (SR.Name = '..')) then // ����� �� ���� ������ . � ..
      begin
        Continue; // ���������� ����
      end;
      if MatchStrings(SR.Name, '*.xml') then
      begin
        LStatus.Caption := '���������� ����� ����������� ' + SR.Name;
        LStatus.Repaint;
        LogMemo.Lines.Add('���������� ����� ����������� ' + SR.Name);
        if FileExists(PluginPath + dirLangs + SR.Name) then
          DeleteFile(PluginPath + dirLangs + SR.Name);
        if CopyFileEx(PChar(PluginPath + 'temp\' + SR.Name), PChar(PluginPath + dirLangs + SR.Name), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS) then
        begin
          DeleteFile(PluginPath + 'temp\' + SR.Name);
          LogMemo.Lines.Add('���������� ����� ����������� ' + SR.Name + ' ���������.');
        end;
      end;
      if MatchStrings(SR.Name, '*.exe') then
      begin
        LStatus.Caption := '���������� ������������ ����� ' + SR.Name;
        LStatus.Repaint;
        LogMemo.Lines.Add('���������� ������������ ����� ' + SR.Name);
        if FileExists(PluginPath + SR.Name) then
          DeleteFile(PluginPath + SR.Name);
        if CopyFileEx(PChar(PluginPath + 'temp\' + SR.Name), PChar(PluginPath + SR.Name), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS) then
        begin
          DeleteFile(PluginPath + 'temp\' + SR.Name);
          LogMemo.Lines.Add('���������� ������������ ����� ' + SR.Name + ' ���������.');
        end;
      end;
      if MatchStrings(SR.Name, '*.dll') then
      begin
        LStatus.Caption := '���������� ����� ��������� ' + SR.Name;
        LStatus.Repaint;
        LogMemo.Lines.Add('���������� ����� ��������� ' + SR.Name);
        if FileExists(PluginPath + SR.Name) then
          DeleteFile(PluginPath + SR.Name);
        if CopyFileEx(PChar(PluginPath + 'temp\' + SR.Name), PChar(PluginPath + SR.Name), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS) then
        begin
          DeleteFile(PluginPath + 'temp\' + SR.Name);
          LogMemo.Lines.Add('���������� ����� ��������� ' + SR.Name + ' ���������.');
        end;
      end;
      if MatchStrings(SR.Name, '*.msg') then
      begin
        LStatus.Caption := '���������� ���������������� �����  ' + SR.Name;
        LStatus.Repaint;
        LogMemo.Lines.Add('���������� ���������������� ����� ' + SR.Name);
        if FileExists(PluginPath + SR.Name) then
          DeleteFile(PluginPath + SR.Name);
        if CopyFileEx(PChar(PluginPath + 'temp\' + SR.Name), PChar(PluginPath + SR.Name), nil, nil, nil, COPY_FILE_FAIL_IF_EXISTS) then
        begin
          DeleteFile(PluginPath + 'temp\' + SR.Name);
          LogMemo.Lines.Add('���������� ���������������� ����� ' + SR.Name + ' ���������.');
        end;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

procedure TMainForm.IMDownloader1Break(Sender: TObject);
begin
  LStatus.Caption := '���������� �����������.';
  LAmount.Caption := CurrToStr(IMDownloader1.AcceptedSize/1024)+' �����';
  LAmount.Repaint;
  ButtonUpdateEnableStart;
end;

procedure TMainForm.IMDownloader1Downloading(Sender: TObject; AcceptedSize, MaxSize: Cardinal);
begin
  QueryPerformanceCounter(C2);
  ProgressBarDownloads.Max := MaxSize;
  ProgressBarDownloads.Position := AcceptedSize;
  LStatus.Caption := '���� ��������...';
  LAmount.Caption := CurrToStr(AcceptedSize/1024)+' �����';
  LAmount.Repaint;
  LSpeed.Caption := CurrToStr((AcceptedSize/1024)/((C2 - C1) / iCounterPerSec))+' �����/���';
  LSpeed.Repaint;
end;

procedure TMainForm.IMDownloader1Error(Sender: TObject; E: TIMDownloadError);
var
  S: String;
begin
  case E of
    deInternetOpen: S := '������ ��� �������� ������.';
    deInternetOpenUrl: S := '������ ��� ������������ �����.';
    deDownloadingFile: S := '������ ��� ������ �����.';
    deRequest: S := '������ ��� ������� ������ ����� ������-������.';
  end;
  LStatus.Caption := S;
  LogMemo.Lines.Add(S);
  LAmount.Caption := CurrToStr(IMDownloader1.AcceptedSize/1024)+' �����';
  LAmount.Repaint;
  if not TrueHeader then
  begin
    LFileName.Caption := '�� ��������';
    LFileDescription.Caption := '�� ��������';
    LFileMD5.Caption := '�� ��������';
  end;
  ButtonUpdateEnableStart;
end;

{ ��������� ���������� � �����
  ������ ���������:
  ���_�����|�������_�����|MD5Sum_�����|������_�����
}
procedure TMainForm.IMDownloader1Headers(Sender: TObject; Headers: string);
var
  HeadersStrList: TStringList;
  I: Integer;
  Size: String;
  Ch: Char;
  ResultFilename, ResultFileDesc, ResultMD5Sum, ResultHeaders: String;
  ResultFileSize: Integer;
begin
  //LogMemo.Lines.Add(Headers);
  HeadersStrList := TStringList.Create;
  HeadersStrList.Clear;
  HeadersStrList.Text := Headers;
  HeadersStrList.Delete(HeadersStrList.Count-1); // ��������� ������� �������� ������ CRLF
  if HeadersStrList.Count > 0 then
  begin
    ResultFilename := 'Test';
    ResultFileDesc := 'Test';
    ResultMD5Sum := '00000000000000000000000000000000';
    ResultFileSize := 0;
    LogMemo.Lines.Add('������ ���������...');
    for I := 0 to HeadersStrList.Count - 1 do
    begin
      //LogMemo.Lines.Add(HeadersStrList[I]);
      // ������ ������ ����
      // Content-Disposition: attachment; filename="���-�����"
      // ����� ������ ��������� � ��������� HTTP-�������
      // ������ ��� ������ get.php
      if pos('content-disposition', lowercase(HeadersStrList[I])) > 0 then
      begin
        ResultFilename := HeadersStrList[I];
        Delete(ResultFilename, 1, Pos('"', HeadersStrList[I]));
        Delete(ResultFilename, Length(ResultFilename),1);
        //LogMemo.Lines.Add('Filename: '+ResultFilename);
      end;
      // ������ ������ ����
      // Content-Description: Desc
      if pos('content-description', lowercase(HeadersStrList[I])) > 0 then
      begin
        ResultFileDesc := HeadersStrList[I];
        Delete(ResultFileDesc, 1, Pos(':', HeadersStrList[I]));
        Delete(ResultFileDesc, 1,1);
        //LogMemo.Lines.Add('Description: '+ResultFileDesc);
      end;
      // ������ ������ ����
      // Content-MD5Sum: MD5
      if pos('content-md5sum', lowercase(HeadersStrList[I])) > 0 then
      begin
        ResultMD5Sum := HeadersStrList[I];
        Delete(ResultMD5Sum, 1, Pos(':', HeadersStrList[I]));
        Delete(ResultMD5Sum, 1,1);
        //LogMemo.Lines.Add('MD5: '+ResultMD5Sum);
      end;
      // ������ ������ ����
      // Content-Length: ������
      if pos('content-length', lowercase(HeadersStrList[i])) > 0 then
      begin
        Size := '';
        for Ch in HeadersStrList[I]do
          if Ch in ['0'..'9'] then
            Size := Size + Ch;
        ResultFileSize := StrToIntDef(Size,-1);// + Length(HeadersStrList.Text);
      end;
    end;
    ResultHeaders := ResultFilename + '|' + ResultFileDesc + '|' + ResultMD5Sum + '|' + IntToStr(ResultFileSize) + '|';
    if(ResultHeaders <> 'Test|Test|00000000000000000000000000000000|' + IntToStr(ResultFileSize) + '|') then
    begin
      LogMemo.Lines.Add('������ ���������:');
      LogMemo.Lines.Add('��� ����� = ' + ResultFilename);
      LogMemo.Lines.Add('�������� ����� = ' + ResultFileDesc);
      LogMemo.Lines.Add('MD5 ����� = ' + ResultMD5Sum);
      LogMemo.Lines.Add('������ ����� = ' + IntToStr(ResultFileSize));
      LFileName.Caption := ResultFilename;
      LFileDescription.Caption := ResultFileDesc;
      LFileMD5.Caption := ResultMD5Sum;
      HeaderFileName := ResultFilename;
      HeaderMD5 := ResultMD5Sum;
      HeaderFileSize := ResultFileSize;
      if (CurrentUpdateStep = 0) and FileExists(PluginPath+HeaderFileName) then
        DeleteFile(PluginPath+HeaderFileName);
      TrueHeader := True;
    end
    else
    begin
      LogMemo.Lines.Add('������������ ��������� ������ � �������.');
      HeaderFileName := 'Test';
      HeaderMD5 := '00000000000000000000000000000000';
      HeaderFileSize := 0;
      TrueHeader := False;
    end;
  end;
  HeadersStrList.Free;
end;

procedure TMainForm.IMDownloader1MD5Checked(Sender: TObject; MD5Correct, SizeCorrect: Boolean; MD5Str: string);
begin
  MD5InMemory := MD5Str;
  IMMD5Correct := MD5Correct;
  IMSizeCorrect := SizeCorrect;
end;

procedure TMainForm.IMDownloader1StartDownload(Sender: TObject);
begin
  QueryPerformanceFrequency(iCounterPerSec);
  QueryPerformanceCounter(C1);
  ButtonUpdateEnableStop;
  LStatus.Caption := '������������� ����������...';
  LAmount.Caption := '0 �����';
  LSpeed.Caption := '0 �����/���';
  LogMemo.Lines.Add('������������� ���������� c URL ' + IMDownloader1.URL);
end;

procedure TMainForm.ButtonUpdateStopClick(Sender: TObject);
begin
  IMDownloader1.BreakDownload;
end;

procedure TMainForm.CBUseProxyClick(Sender: TObject);
begin
  if CBUseProxy.Checked then
  begin
    EProxyAddress.Enabled := True;
    EProxyPort.Enabled := True;
    CBProxyAuth.Enabled := True;
  end
  else
  begin
    EProxyAddress.Enabled := False;
    EProxyPort.Enabled := False;
    CBProxyAuth.Enabled := False;
  end;
end;

procedure TMainForm.CBProxyAuthClick(Sender: TObject);
begin
  if CBProxyAuth.Checked then
  begin
    EProxyUser.Enabled := True;
    EProxyUserPasswd.Enabled := True;
  end
  else
  begin
    EProxyUser.Enabled := False;
    EProxyUserPasswd.Enabled := False;
  end;
end;

procedure TMainForm.ButtonUpdateEnableStart;
begin
  ButtonUpdate.OnClick := ButtonUpdateStartClick;
  ButtonUpdate.Caption := '��������';
  ButtonSettings.Enabled := True;
  CBIMClientType.Enabled := True;
  CBDBType.Enabled := True;
end;

procedure TMainForm.ButtonUpdateEnableStop;
begin
  ButtonUpdate.OnClick := ButtonUpdateStopClick;
  ButtonUpdate.Caption := '����������';
  ButtonSettings.Enabled := False;
  CBIMClientType.Enabled := False;
  CBDBType.Enabled := False;
end;

procedure TMainForm.CBDBTypeChange(Sender: TObject);
begin
  DBType := CBDBType.Items[CBDBType.ItemIndex];
end;

procedure TMainForm.CBIMClientTypeChange(Sender: TObject);
begin
  IMClientType := CBIMClientType.Items[CBIMClientType.ItemIndex];
end;

{ ����� ����� }
procedure TMainForm.CBLangChange(Sender: TObject);
begin
  FLanguage := CBLang.Items[CBLang.ItemIndex];
  DefaultLanguage := CBLang.Items[CBLang.ItemIndex];
  CoreLanguageChanged;
end;

{ ��������� ������ �������� ������ � ���������� ������ }
procedure TMainForm.FindLangFile;
var
  SR: TSearchRec;
  I: Integer;
begin
  CBLang.Items.Clear;
  if FindFirst(PluginPath + dirLangs + '\*.*', faAnyFile or faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr = faDirectory) and ((SR.Name = '.') or (SR.Name = '..')) then // ����� �� ���� ������ . � ..
      begin
        Continue; // ���������� ����
      end;
      if MatchStrings(SR.Name, '*.xml') then
      begin
        // ��������� ����
        CBLang.Items.Add(ExtractFileNameEx(SR.Name, False));
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  if CBLang.Items.Count > 0 then
  begin
    for I := 0 to CBLang.Items.Count-1 do
    begin
      if CBLang.Items[I] = CoreLanguage then
        CBLang.ItemIndex := I;
    end;
  end
  else
  begin
    CBLang.Items.Add('�� ������ ���� �����������');
    CBLang.ItemIndex := 0;
    CBLang.Enabled := False;
  end;
end;

{ ����� ����� ���������� �� ������� WM_LANGUAGECHANGED }
procedure TMainForm.OnLanguageChanged(var Msg: TMessage);
begin
  LoadLanguageStrings;
end;

{ ������� ��� �������������� ��������� }
procedure TMainForm.CoreLanguageChanged;
var
  LangFile: String;
begin
  if CoreLanguage = '' then
    Exit;
  try
    LangFile := PluginPath + dirLangs + CoreLanguage + '.xml';
    if FileExists(LangFile) then
      LangDoc.LoadFromFile(LangFile)
    else
    begin
      if FileExists(PluginPath + dirLangs + defaultLangFile) then
        LangDoc.LoadFromFile(PluginPath + dirLangs + defaultLangFile)
      else
      begin
        MsgDie(ProgramsName, 'Not found any language file!');
        Exit;
      end;
    end;
    Global.CoreLanguage := CoreLanguage;
    SendMessage(MainFormHandle, WM_LANGUAGECHANGED, 0, 0);
    SendMessage(AboutFormHandle, WM_LANGUAGECHANGED, 0, 0);
  except
    on E: Exception do
      MsgDie(ProgramsName, 'Error on CoreLanguageChanged: ' + E.Message + sLineBreak +
        'CoreLanguage: ' + CoreLanguage);
  end;
end;

{ ��� �������������� ��������� }
procedure TMainForm.LoadLanguageStrings;
begin
  if IMClientType <> 'Unknown' then
    Caption := ProgramsName + ' for ' + IMClientType
  else
    Caption := ProgramsName;
  ButtonUpdate.Caption := GetLangStr('HistoryToDBSyncLogFormReloadLogButton');
  ButtonSettings.Caption := GetLangStr('SettingsButton');
  LDBType.Caption := GetLangStr('LDBType');
  LLanguage.Caption := GetLangStr('Language');
  TabSheetSettings.Caption := GetLangStr('GeneralSettings');
  TabSheetConnectSettings.Caption := GetLangStr('ConnectionSettings');
  TabSheetLog.Caption := GetLangStr('Logs');
  GBSettings.Caption := GetLangStr('GeneralSettings');
end;

function TMainForm.EndTask(TaskName, FormName: String): Boolean;
begin
  Result := False;
  if IsProcessRun(TaskName) then
  begin
    LogMemo.Lines.Add('� ������ ������ ������� ' + TaskName + ' (PID: '+IntToStr(GetProcessID(TaskName))+')');
    LogMemo.Lines.Add('���������� ������� ����������...');
    OnSendMessageToOneComponent(FormName, '003');
    OnSendMessageToOneComponent(FormName, '009');
    Sleep(1000);
    LogMemo.Lines.Add('�������� ���� ������� '+TaskName+' � ������...');
    if IsProcessRun(TaskName) then
    begin
      LogMemo.Lines.Add('� ������ ������ ������� ' + TaskName + ' (PID: '+IntToStr(GetProcessID(TaskName))+')');
      LogMemo.Lines.Add('�������� ������������� ��������� ������� '+TaskName);
      if KillTask(TaskName) = 1 then
      begin
        LogMemo.Lines.Add('������� '+TaskName+' ������������� ��������.');
        Result := True;
      end
      else
      begin
        LogMemo.Lines.Add('������� '+TaskName+' �� ����� ���� ������������� ��������.');
        LogMemo.Lines.Add('�������� ���� ���������� �� SeDebugPrivilege � ������� ��� ��� ��������� ������� '+TaskName);
        if ProcessTerminate(GetProcessID(TaskName)) then
        begin
          LogMemo.Lines.Add('������� '+TaskName+' ������������� �������� ��� SeDebugPrivilege.');
          Result := True;
        end
        else
        begin
          LogMemo.Lines.Add('������� '+TaskName+' �� ����� ���� ������������� �������� ���� ��� SeDebugPrivilege.');
          Result := False;
        end;
      end;
    end
    else
    begin
      LogMemo.Lines.Add('������� '+TaskName+' �� ������ � ������.');
      Result := True;
    end;
  end
  else
  begin
    LogMemo.Lines.Add('������� '+TaskName+' �� ������ � ������.');
    Result := True;
  end;
end;

end.