// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

interface "ISFTP File"
{
    Access = Public;
    procedure MoveTo(Destination: Text): Boolean
    procedure Name(): Text
    procedure FullName(): Text
    procedure IsDirectory(): Boolean
    procedure Length(): BigInteger
    procedure LastWriteTime(): DateTime
}