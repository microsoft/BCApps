// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Reflection;

// Necessary because codeunit TypeHelper hijacks the Evaluate() command so it cannot be used in it.
codeunit 709 "Type Helper Evaluate"
{
    Access = internal;

    internal procedure EvaluateBigInteger(var BigIntegerValue: BigInteger; TextValue: Text): Boolean
    begin
        exit(Evaluate(BigIntegerValue, TextValue));
    end;
}
