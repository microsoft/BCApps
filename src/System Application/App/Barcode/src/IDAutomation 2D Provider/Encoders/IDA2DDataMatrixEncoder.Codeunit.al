// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;

using System;

codeunit 9217 "IDA 2D Data Matrix Encoder" implements "Barcode Font Encoder 2D"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure EncodeFont(InputText: Text): Text
    var
        DotNetFontEncoder: DotNet DataMatrixFontEncoder;
        NullString: DotNet String;
        EncodingModes: DotNet EncodingModesDM;
        OutputTypes: DotNet OutputTypesDM;
    begin
        DotNetFontEncoder := DotNetFontEncoder.DataMatrix();

        // Enum value for the Ascii encoding as the enum name have changed from ASCII to Ascii in the .Net library and we want to avoid breaking changes in our code. This is the
        // default options to encode for the fonts we provide.        
        EncodingModes := 3;
        exit(DotNetFontEncoder.EncodeDM(InputText, true, EncodingModes, -1, OutputTypes::IDA2DFont, NullString));
    end;
}