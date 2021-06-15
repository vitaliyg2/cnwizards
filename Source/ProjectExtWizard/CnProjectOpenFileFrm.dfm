inherited CnProjectOpenFileForm: TCnProjectOpenFileForm
  Top = 250
  Caption = 'Unit List of Project Group'
  PixelsPerInch = 120
  TextHeight = 13
  inherited StatusBar: TStatusBar
    OnDrawPanel = StatusBarDrawPanel
  end
  inherited pnlMain: TPanel
    inherited lvList: TListView
      Top = 0
      Columns = <
        item
          Caption = 'Unit'
          Width = 210
        end
        item
          Caption = 'Path'
        end
        item
          Alignment = taRightJustify
          Caption = 'Size(Byte)'
          Width = 80
        end
        item
          Caption = 'Type'
          Width = 100
        end
        item
          Caption = 'Project'
          Width = 140
        end
        item
          Caption = 'File State'
          Width = 72
        end>
      OwnerData = True
      OnData = lvListData
    end
  end
  inherited ActionList: TActionList
    inherited actOpen: TAction
      Hint = 'Open Selected Unit'
    end
    inherited actAttribute: TAction
      Hint = 'Show Property of Selected Unit File'
    end
    inherited actCopy: TAction
      Hint = 'Copy Selected Unit Name to Clipboard'
    end
    inherited actSelectAll: TAction
      Caption = 'Select A&ll Units'
      Hint = 'Select All Units'
    end
    inherited actMatchStart: TAction
      Caption = 'Match Unit Name &Start'
      Hint = 'Match Unit Name Start'
    end
    inherited actMatchAny: TAction
      Caption = 'Match &All Parts of Unit Name'
      Hint = 'Match All Parts of Unit Name'
    end
    inherited actHookIDE: TAction
      Hint = 'Hook Project Unit List to IDE'
    end
    inherited actQuery: TAction
      Caption = '&Prompt when Open More than ONE Unit'
      Hint = 'Prompt when Open More than ONE Unit'
    end
  end
  object tmrReadFiles: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrReadFilesTimer
    Left = 408
    Top = 8
  end
end
