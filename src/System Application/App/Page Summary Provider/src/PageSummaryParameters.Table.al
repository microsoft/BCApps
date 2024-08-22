// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

table 2719 "Page Summary Parameters"
{
    DataClassification = SystemMetadata;
    Caption = 'Page Summary Settings';
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the ID of the page for which the summary is requested. This parameter is mandatory.';
        }
        field(2; "Record SystemID"; Guid)
        {
            Caption = 'Record SystemID';
            ToolTip = 'Specifies the SystemID of the record for which the summary is requested.';
        }
        field(3; Bookmark; Text[2024])
        {
            Caption = 'Bookmark';
            ToolTip = 'Specifies the bookmark of the record for which the summary is requested.';
        }
        field(4; "Include Binary Data"; Boolean)
        {
            Caption = 'Include Media';
            ToolTip = 'Specifies if the media should be included in the summary.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Page ID")
        {
        }
    }

    /// <summary>
    /// Initializes the page summary parameters record from JSON.
    /// </summary>
    /// <param name="PageSummaryParameterJson">Page summary parameters in JSON format</param>
    procedure FromJson(PageSummaryParameterJson: Text)
    var
        PageSummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        PageSummaryProviderImpl.InitializePageSummarySettingsFromJson(PageSummaryParameterJson, Rec);
    end;
}