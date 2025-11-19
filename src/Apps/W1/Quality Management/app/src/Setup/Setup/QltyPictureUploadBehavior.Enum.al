// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.Setup;

/// <summary>
/// This is used to help determine what to do when a picture is uploaded to a test.
/// </summary>
enum 20420 "Qlty. Picture Upload Behavior"
{
    Caption = 'Quality Picture Upload Behavior';

    value(0; "Do nothing")
    {
        Caption = 'Do nothing';
    }
    value(1; "Attach document")
    {
        Caption = 'Attach document';
    }
    value(2; "Attach and upload to OneDrive")
    {
        Caption = 'Attach and upload to OneDrive';
    }
}
