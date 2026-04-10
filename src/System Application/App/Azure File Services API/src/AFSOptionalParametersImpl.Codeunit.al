// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

/// <summary>
/// Holds procedures to format headers and parameters to be used in requests.
/// </summary>
codeunit 8963 "AFS Optional Parameters Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AFSFormatHelper: Codeunit "AFS Format Helper";
        RequestHeaders: Dictionary of [Text, Text];
        Parameters: Dictionary of [Text, Text];

    procedure Range(BytesStartValue: Integer; BytesEndValue: Integer)
    var
        RangeBytesLbl: Label 'bytes=%1-%2', Comment = '%1 = Start Range; %2 = End Range', Locked = true;
    begin
        SetRequestHeader('x-ms-range', StrSubstNo(RangeBytesLbl, BytesStartValue, BytesEndValue));
    end;

    procedure Write("Value": Enum "AFS Write")
    begin
        SetRequestHeader('x-ms-write', Format("Value"));
    end;

    procedure LeaseId("Value": Guid)
    begin
        SetRequestHeader('x-ms-lease-id', AFSFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower()));
    end;

    procedure LeaseAction("Value": Enum "AFS Lease Action")
    begin
        SetRequestHeader('x-ms-lease-action', Format("Value"));
    end;

    procedure LeaseDuration("Value": Integer)
    begin
        SetRequestHeader('x-ms-lease-duration', Format("Value"));
    end;

    procedure ProposedLeaseId("Value": Guid)
    begin
        SetRequestHeader('x-ms-proposed-lease-id', AFSFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower()));
    end;

    procedure ClientRequestId("Value": Text)
    begin
        SetRequestHeader('x-ms-client-request-id', "Value");
    end;

    procedure FileLastWriteTime("Value": Enum "AFS File Last Write Time")
    begin
        SetRequestHeader('x-ms-file-last-write-time', Format("Value"));
    end;

    procedure FileRequestIntent("Value": Text)
    begin
        SetRequestHeader('x-ms-file-request-intent', "Value");
    end;

    procedure FilePermission("Value": Text)
    begin
        SetRequestHeader('x-ms-file-permission', "Value");
    end;

    procedure FilePermissionKey("Value": Text)
    begin
        SetRequestHeader('x-ms-file-permission-key', "Value");
    end;

    procedure FileAttributes("Value": List of [Enum "AFS File Attribute"])
    var
        FileAttribute: Enum "AFS File Attribute";
        ValueText: Text;
    begin
        foreach FileAttribute in "Value" do
            ValueText += Format(FileAttribute) + ',';
        ValueText := ValueText.TrimEnd(',');

        SetRequestHeader('x-ms-file-attributes', ValueText);
    end;

    procedure FileCreationTime("Value": DateTime)
    begin
        SetParameter('x-ms-file-creation-time', AFSFormatHelper.GetRfc1123DateTime("Value"));
    end;

    procedure FileLastWriteTime("Value": DateTime)
    begin
        SetParameter('x-ms-file-last-write-time', AFSFormatHelper.GetRfc1123DateTime("Value"));
    end;

    procedure FileChangeTime("Value": DateTime)
    begin
        SetParameter('x-ms-file-change-time', AFSFormatHelper.GetRfc1123DateTime("Value"));
    end;

    procedure Meta("Key": Text; "Value": Text)
    begin
        SetRequestHeader('x-ms-meta-' + "Key", "Value");
    end;

    procedure FilePermissionCopyMode("Value": Enum "AFS File Permission Copy Mode")
    begin
        SetRequestHeader('x-ms-file-permission-copy-mode', Format("Value"));
    end;

    procedure CopySource("Value": Text)
    begin
        SetRequestHeader('x-ms-copy-source', "Value");
    end;

    procedure AllowTrailingDot("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-allow-trailing-dot', ValueText);
    end;

    procedure FileRenameReplaceIfExists("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-file-rename-replace-if-exists', ValueText);
    end;

    procedure FileRenameIgnoreReadOnly("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-file-rename-ignore-readonly', ValueText);
    end;

    procedure SourceLeaseId("Value": Guid)
    begin
        SetRequestHeader('x-ms-source-lease-id', AFSFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower()));
    end;

    procedure DestinationLeaseId("Value": Guid)
    begin
        SetRequestHeader('x-ms-destination-lease-id', AFSFormatHelper.RemoveCurlyBracketsFromString(Format("Value").ToLower()));
    end;

    procedure FileCopyIgnoreReadOnly("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-file-copy-ignore-readonly', ValueText);
    end;

    procedure FileCopySetArchive("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-file-copy-set-archive', ValueText);
    end;

    procedure FileExtendedInfo("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-file-extended-info', ValueText);
    end;

    procedure RangeGetContentMD5("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-range-get-content-md5', ValueText);
    end;

    procedure Recursive("Value": Boolean)
    var
        ValueText: Text;
    begin
        // Set as text, because otherwise it might give different formatted values based on language locale
        ValueText := ConvertBooleanToText("Value");

        SetRequestHeader('x-ms-recursive', ValueText);
    end;

    procedure Timeout("Value": Integer)
    begin
        SetParameter('timeout', Format("Value"));
    end;

    procedure Prefix("Value": Text)
    begin
        SetParameter('prefix', "Value");
    end;

    procedure ShareSnapshot("Value": DateTime)
    begin
        SetParameter('sharesnapshot', AFSFormatHelper.GetRfc1123DateTime("Value"));
    end;

    procedure Marker("Value": Text)
    begin
        SetParameter('marker', "Value");
    end;

    procedure MaxResults("Value": Integer)
    begin
        SetParameter('maxresults', Format("Value"));
    end;

    procedure Include("Value": List of [Enum "AFS Property"])
    var
        Property: Enum "AFS Property";
        ValueText: Text;
    begin
        foreach Property in "Value" do
            ValueText += Format(Property) + ',';
        ValueText := ValueText.TrimEnd(',');

        SetParameter('include', ValueText);
    end;

    local procedure SetRequestHeader(Header: Text; HeaderValue: Text)
    begin
        RequestHeaders.Remove(Header);
        RequestHeaders.Add(Header, HeaderValue);
    end;

    procedure GetRequestHeaders(): Dictionary of [Text, Text]
    begin
        exit(RequestHeaders);
    end;

    local procedure SetParameter(Header: Text; HeaderValue: Text)
    begin
        Parameters.Remove(Header);
        Parameters.Add(Header, HeaderValue);
    end;

    local procedure ConvertBooleanToText("Value": Boolean) ValueText: Text
    begin
        if "Value" then
            ValueText := 'true'
        else
            ValueText := 'false';
    end;

    procedure GetParameters(): Dictionary of [Text, Text]
    begin
        exit(Parameters);
    end;
}
