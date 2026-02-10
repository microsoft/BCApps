// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// This is used to help determine what to do when a picture is uploaded to an inspection.
/// </summary>
enum 20420 "Qlty. Add. Picture Handling"
{
    Caption = 'Additional Picture Handling';

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; "Save as attachment")
    {
        Caption = 'Save as attachment';
    }
    value(2; "Save as attachment and upload to OneDrive")
    {
        Caption = 'Save as attachment and upload to OneDrive';
    }
}
