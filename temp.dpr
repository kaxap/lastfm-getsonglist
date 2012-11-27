program temp;

{$APPTYPE CONSOLE}

uses Classes, Windows, Messages, SysUtils, StrUtils, UrlMon;

const
  INET_E_INVALID_URL = $800C000;
  INET_E_NO_SESSION = $800C0003;
  INET_E_CANNOT_CONNECT = $800C0004;
  INET_E_RESOURCE_NOT_FOUND = $800C0005;
  INET_E_OBJECT_NOT_FOUND = $800C0006;
  INET_E_DATA_NOT_AVAILABLE = $800C0007;
  INET_E_DOWNLOAD_FAILURE = $800C0008;
  INET_E_AUTHENTICATION_REQUIRED = $800C0009;
  INET_E_NO_VALID_MEDIA = $800C000A;
  INET_E_CONNECTION_TIMEOUT = $800C000B;
  INET_E_INVALID_REQUEST = $800C000C;
  INET_E_UNKNOWN_PROTOCOL = $800C000D;
  INET_E_SECURITY_PROBLEM = $800C000E;
  INET_E_CANNOT_LOAD_DATA = $800C000F;
  INET_E_CANNOT_INSTANTIATE_OBJECT = $800C0010;
  INET_E_INVALID_CERTIFICATE = $800C0019;
  INET_E_REDIRECT_FAILED = $800C0014;
  INET_E_REDIRECT_TO_DIR = $800C0015;
  INET_E_CANNOT_LOCK_REQUEST = $800C0016;
  INET_E_USE_EXTEND_BINDING = $800C0017;
  INET_E_TERMINATED_BIND = $800C0018;
  INET_E_ERROR_FIRST = $800C0002;
  INET_E_CODE_DOWNLOAD_DECLINED = $800C0100;
  INET_E_RESULT_DISPATCHED = $800C0200;
  INET_E_CANNOT_REPLACE_SFP_FILE = $800C0300;
  INET_E_CODE_INSTALL_SUPPRESSED = $800C0400;
  INET_E_CODE_INSTALL_BLOCKED_BY_HASH_POLICY = $800C0500;

  SIZE_FILE_MIN = 1024 * 800; //100 KB

  function HResultToText(hr: HRESULT): String;
  begin
    case hr of
      INET_E_INVALID_URL: Result := 'INET_E_INVALID_URL';
      INET_E_NO_SESSION: Result := 'INET_E_NO_SESSION';
      INET_E_CANNOT_CONNECT: Result := 'INET_E_CANNOT_CONNECT';
      INET_E_RESOURCE_NOT_FOUND: Result := 'INET_E_RESOURCE_NOT_FOUND';
      INET_E_OBJECT_NOT_FOUND: Result := 'INET_E_OBJECT_NOT_FOUND';
      INET_E_DATA_NOT_AVAILABLE: Result := 'INET_E_DATA_NOT_AVAILABLE';
      INET_E_DOWNLOAD_FAILURE: Result := 'INET_E_DOWNLOAD_FAILURE';
      INET_E_AUTHENTICATION_REQUIRED: Result := 'INET_E_AUTHENTICATION_REQUIRED';
      INET_E_NO_VALID_MEDIA: Result := 'INET_E_NO_VALID_MEDIA';
      INET_E_CONNECTION_TIMEOUT: Result := 'INET_E_CONNECTION_TIMEOUT';
      INET_E_INVALID_REQUEST: Result := 'INET_E_INVALID_REQUEST';
      INET_E_UNKNOWN_PROTOCOL: Result := 'INET_E_UNKNOWN_PROTOCOL';
      INET_E_SECURITY_PROBLEM: Result := 'INET_E_SECURITY_PROBLEM';
      INET_E_CANNOT_LOAD_DATA: Result := 'INET_E_CANNOT_LOAD_DATA';
      INET_E_CANNOT_INSTANTIATE_OBJECT: Result := 'INET_E_CANNOT_INSTANTIATE_OBJECT';
      INET_E_INVALID_CERTIFICATE: Result := 'INET_E_INVALID_CERTIFICATE';
      INET_E_REDIRECT_FAILED: Result := 'INET_E_REDIRECT_FAILED';
      INET_E_REDIRECT_TO_DIR: Result := 'INET_E_REDIRECT_TO_DIR';
      INET_E_CANNOT_LOCK_REQUEST: Result := 'INET_E_CANNOT_LOCK_REQUEST';
      INET_E_USE_EXTEND_BINDING: Result := 'INET_E_USE_EXTEND_BINDING';
      INET_E_TERMINATED_BIND: Result := 'INET_E_TERMINATED_BIND';
      INET_E_ERROR_FIRST: Result := 'INET_E_ERROR_FIRST';
      INET_E_CODE_DOWNLOAD_DECLINED: Result := 'INET_E_CODE_DOWNLOAD_DECLINED';
      INET_E_RESULT_DISPATCHED: Result := 'INET_E_RESULT_DISPATCHED';
      INET_E_CANNOT_REPLACE_SFP_FILE: Result := 'INET_E_CANNOT_REPLACE_SFP_FILE';
      INET_E_CODE_INSTALL_SUPPRESSED: Result := 'INET_E_CODE_INSTALL_SUPPRESSED';
      INET_E_CODE_INSTALL_BLOCKED_BY_HASH_POLICY: Result := 'INET_E_CODE_INSTALL_BLOCKED_BY_HASH_POLICY';
    else
      Result := 'Unknown error';
    end;
  end;

  {function GetErrorCode(hr: HRESULT): String;
  begin
    FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER OR
      FORMAT_MESSAGE_FROM_SYSTEM OR
      FORMAT_MESSAGE_IGNORE_INSERTS, nil, hr,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),)
    SysErrorMessage()
  end;}


  function FileSize(fileName : wideString) : Int64;
  var
    sr : TSearchRec;
  begin
    if FindFirst(fileName, faAnyFile, sr ) = 0 then
       result := Int64(sr.FindData.nFileSizeHigh) shl Int64(32) + Int64(sr.FindData.nFileSizeLow)
    else
       result := -1;

    FindClose(sr) ;
  end;

  function replacePluses(const s: String): String;
  var
    i: Integer;
  begin
    Result := '';
    for i := 1 to Length(s) do
    if s[i] = '+' then Result := Result + ' ' else
      Result := Result + s[i];
  end;

  function getStringFromBeginning(const s: String; c: Char; p: Integer): String;
  var
    i: Integer;
  begin
    Result := '';
    if Length(s) < p then
       Exit;
    for i := p downto 1 do
    begin
      if s[i] <> c then
        Result := s[i] + Result
      else
        Exit;
    end;
  end;

  function getStringToEnd(const s: String; c: Char; p: Integer): String;
  var
    i: Integer;
  begin
    Result := '';
    if Length(s) < p then
       Exit;
    for i := p to Length(s) do
    begin
      if s[i] <> c then
        Result := Result + s[i]
      else
        Exit;
    end;
  end;

  function getDownloadListMp3Skull(const search: String; List: TStrings): Boolean;
  var
    i, j, k: Integer;
    ss: TStringList;
    hr: HRESULT;
    s: String;
  begin
    List.Clear;
    Result := False;
    hr := URLDownloadToFile(nil, PChar('http://mp3skull.com/search.php?q=' + search),
      'page.html', 0, nil);

    if FAILED(hr) then
      Exit;

    ss := TStringList.Create;
    try
      ss.LoadFromFile('page.html');
      for i := 0 to ss.Count - 1 do
      begin
        j := Pos('.mp3"', ss[i]);
        if j > 0 then
        begin
          s := getStringFromBeginning(ss[i], '"', j + 3);
          List.Add(s);
        end;

      end;
    finally
      ss.Free;
    end;

    Result := True;
  end;

  function getDownloadListSoundCloud(const search: String; List: TStrings;
    artist: String = ''): Boolean;

    function scCheckGenuine(artist: String; ss: TStrings;
      start: Integer): Boolean;
    var
      i, j, k: Integer;
      s: String;
    begin
      Result := False;
      if start >= ss.Count then
        Exit;

      for i := start downto 0 do
      begin
        j := Pos('<h3>', ss[i]);
        if j > 0 then
        begin
          j := Pos('</h3>', ss[i]);
          if j > 0 then
          begin
            s := getStringFromBeginning(ss[i], '>', j - 5);
            Result := Pos(AnsiLowerCase(artist), AnsiLowerCase(s)) > 0;
          end;
          Break;
        end;
      end;

    end;

  var
    i, j, k: Integer;
    ss: TStringList;
    hr: HRESULT;
    s: String;
  begin
    List.Clear;
    Result := False;
    hr := URLDownloadToFile(nil, PChar('http://soundcloud.com/search?q%5Bfulltext%5D=' + search),
      'page4.html', 0, nil);

    if FAILED(hr) then
      Exit;

    ss := TStringList.Create;
    try
      ss.LoadFromFile('page4.html');
      for i := 0 to ss.Count - 1 do
      begin
        j := Pos('"http://media.soundcloud.com', ss[i]);
        if j > 0 then
        begin
          s := getStringToEnd(ss[i], '"', j + 1);
          if artist <> '' then
            if NOT scCheckGenuine(artist, ss, i) then Continue;
          List.Add(s);
        end;

      end;
    finally
      ss.Free;
    end;

    Result := True;
  end;

  function getDownloadListAp(const search: String; List: TStrings): Boolean;
  var
    i, j, k: Integer;
    ss: TStringList;
    hr: HRESULT;
    s: String;
  begin
    List.Clear;
    Result := False;
    hr := URLDownloadToFile(nil, PChar('http://www.audiopoisk.com/?q=' + search),
      'page3.html', 0, nil);

    if FAILED(hr) then
      Exit;

    ss := TStringList.Create;
    try
      ss.LoadFromFile('page3.html');
      for i := 0 to ss.Count - 1 do
      begin
        j := Pos('По вашему запросу ничего не найдено.', ss[i]);
        if j > 0 then
        begin
          Result := False;
          List.Clear;
          //ss.Free;
          Exit;
        end;
        j := Pos('.mp3"', ss[i]);
        if j > 0 then
        begin
          s := getStringFromBeginning(ss[i], '"', j + 3);
          List.Add('http://www.audiopoisk.com' + s);
        end;

      end;
    finally
      ss.Free;
    end;

    Result := True;
  end;

  function getTopList(const url: String; List: TStrings; max: Integer = 50): Boolean;
  var
    ss: TStringList;
    i, j, k: Integer;
    s: String;
    prev: String;
    hr: HRESULT;
  begin
    List.Clear;
    Result := False;
    hr := URLDownloadToFile(nil, PChar(url),
      'page2.html', 0, nil);

    if FAILED(hr) then
      Exit;

    prev := '';
    ss := TStringList.Create;
    try
      ss.LoadFromFile('page2.html');
      for i := 0 to ss.Count - 1 do
      begin
        j := Pos('/_/', ss[i]);
        if (j > 0) AND (Pos('/music/', ss[i]) > 0) then
        begin
          k := PosEx('"', ss[i], j);
          if (k > 0) then
          begin
            s := Copy(ss[i], j + 3, k - j - 3);
            if prev <> s then
            begin
              prev := s;
              List.Add(replacePluses(s));
              if List.Count >= max then
                Break;
            end;

          end;
        end;

      end;
    finally
      ss.Free;
    end;

    Result := True;
  end;

  function downloadFile(files: TStrings; const artist, song: String): Boolean;
  var j: Integer;
    hr: HResult;
    filename: String;
  begin
    Result := False;
    for j := 0 to files.Count - 1 do
    begin
      Write('Downloading ', files[j], '...');
      filename := Format('%s - %s.mp3', [artist, song]);
      hr := URLDownloadToFile(nil, PChar(files[j]),
        PChar(filename), 0, nil);
      if SUCCEEDED(hr) AND (FileSize(filename) >= SIZE_FILE_MIN) then
      begin
        Writeln('SUCCESS');
        Result := True;
        Break;
      end else
      begin
        Writeln('failed (' + HResultToText(hr) + ')');
        DeleteFile(filename);
      end;
    end;
  end;

var
  songs, files, ss: TStringList;
  i, j, k: Integer;
  s: String;
  prev: String;
  hr: HRESULT;
  artist: String;
  succ: Boolean;
  max: Integer;
begin
  //usage: program.exe "link_to_lastfm_tracks" "artist name" max_tracks_number

  s := ParamStr(3);
  if s <> '' then
    max := StrToInt(s)
  else
    max := 50;

  songs := TStringList.Create;

  Write('Downloading list... (max = ', max, ')');
  if (NOT getTopList(ParamStr(1), songs, max)) OR (songs.Count = 0) then
  begin
    Writeln('Could not download/parse lastfm');
    Exit;
  end else
  begin
    Writeln('complete (', songs.Count, ' songs)');
  end;

  artist := ParamStr(2);
  Writeln('Engaging search for "', artist, '"');
  files := TStringList.Create;


  for i := 0 to songs.Count - 1 do
  begin
    Writeln('Song name: ', songs[i]);

    Writeln('Searching on soundcloud.com...');
    getDownloadListSoundCloud(artist + ' - ' + songs[i], files, artist);
    Writeln('Found ', files.Count, ' links on soundcloud.com');

    succ := False;
    if files.Count > 0 then
      succ := downloadFile (files, artist, songs[i]);

    if NOT succ then
    begin
      Writeln('Searching on audiopoisk.com...');
      getDownloadListAp(artist + ' - ' + songs[i], files);
      Writeln('Found ', files.Count, ' links on audiopoisk.com');

      if files.Count > 0 then
        succ := downloadFile(files, artist, songs[i]);


      if NOT succ then
      begin

        Writeln('Searching on mp3skull.com...');
        getDownloadListMp3Skull(artist + ' - ' + songs[i], files);
        Writeln('Found ', files.Count, ' links on mp3skull.com');

        if files.Count > 0 then
          succ := downloadFile(files, artist, songs[i]);

      end;
    end;
  end;

end.

improvized unit tests

test for soundcloud
  {files := TStringList.Create;

  artist := 'Philip Glass';

  getDownloadListSoundCloud(artist + ' - ' + 'Facades', files, artist);
  Writeln('facades - ', files.GetText()); //show 0

  getDownloadListSoundCloud(artist + ' - ' + 'Koyaanisqatsi', files, artist);
  Writeln('norm - ',files.GetText()); //show several

  Readln;
  Exit;}

