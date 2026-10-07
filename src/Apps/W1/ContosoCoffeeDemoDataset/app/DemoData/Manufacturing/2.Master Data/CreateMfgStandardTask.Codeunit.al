// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Manufacturing;

using Microsoft.DemoTool.Helpers;

codeunit 4786 "Create Mfg Standard Task"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoManufacturing: Codeunit "Contoso Manufacturing";
    begin
        ContosoManufacturing.InsertStandardTask(BodyAssembly(), BodyAssemblyDescLbl);
        ContosoManufacturing.InsertStandardTaskDescription(BodyAssembly(), 10000, BodyAssemblyInstr1Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(BodyAssembly(), 20000, BodyAssemblyInstr2Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(BodyAssembly(), 30000, BodyAssemblyInstr3Lbl);

        ContosoManufacturing.InsertStandardTask(ReservoirAssembly(), ReservoirAssemblyDescLbl);
        ContosoManufacturing.InsertStandardTaskDescription(ReservoirAssembly(), 10000, ReservoirAssemblyInstr1Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(ReservoirAssembly(), 20000, ReservoirAssemblyInstr2Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(ReservoirAssembly(), 30000, ReservoirAssemblyInstr3Lbl);

        ContosoManufacturing.InsertStandardTask(ElectricalWiring(), ElectricalWiringDescLbl);
        ContosoManufacturing.InsertStandardTaskDescription(ElectricalWiring(), 10000, ElectricalWiringInstr1Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(ElectricalWiring(), 20000, ElectricalWiringInstr2Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(ElectricalWiring(), 30000, ElectricalWiringInstr3Lbl);

        ContosoManufacturing.InsertStandardTask(Testing(), TestingDescLbl);

        ContosoManufacturing.InsertStandardTask(Packing(), PackingDescLbl);
        ContosoManufacturing.InsertStandardTaskDescription(Packing(), 10000, PackingInstr1Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(Packing(), 20000, PackingInstr2Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(Packing(), 30000, PackingInstr3Lbl);

        ContosoManufacturing.InsertStandardTask(Painting(), PaintingDescLbl);
        ContosoManufacturing.InsertStandardTaskDescription(Painting(), 10000, PaintingInstr1Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(Painting(), 20000, PaintingInstr2Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(Painting(), 30000, PaintingInstr3Lbl);
        ContosoManufacturing.InsertStandardTaskDescription(Painting(), 40000, PaintingInstr4Lbl);

        ContosoManufacturing.InsertStandardTask(SubcontractedAssembly(), SubcontractedAssemblyDescLbl);

        ContosoManufacturing.InsertStandardTask(FullSubcontractedProduction(), FullSubcontractedProductionDescLbl);
    end;

    procedure BodyAssembly(): Code[10]
    begin
        exit('ASSY-BODY');
    end;

    procedure ReservoirAssembly(): Code[10]
    begin
        exit('ASSY-RES');
    end;

    procedure ElectricalWiring(): Code[10]
    begin
        exit('ELEC-WIRE');
    end;

    procedure Testing(): Code[10]
    begin
        exit('TESTING');
    end;

    procedure Packing(): Code[10]
    begin
        exit('PACKING');
    end;

    procedure Painting(): Code[10]
    begin
        exit('PAINTING');
    end;

    procedure SubcontractedAssembly(): Code[10]
    begin
        exit('SUBC-ASSY');
    end;

    procedure FullSubcontractedProduction(): Code[10]
    begin
        exit('SUBC-FULL');
    end;

    var
        BodyAssemblyDescLbl: Label 'Body assembly', MaxLength = 100;
        BodyAssemblyInstr1Lbl: Label '1. Mount housing onto base plate', MaxLength = 50;
        BodyAssemblyInstr2Lbl: Label '2. Attach feet and warming plate', MaxLength = 50;
        BodyAssemblyInstr3Lbl: Label '3. Install switch and circuit board', MaxLength = 50;
        ReservoirAssemblyDescLbl: Label 'Reservoir assembly', MaxLength = 100;
        ReservoirAssemblyInstr1Lbl: Label '1. Assemble reservoir body', MaxLength = 50;
        ReservoirAssemblyInstr2Lbl: Label '2. Install heating element and tubing', MaxLength = 50;
        ReservoirAssemblyInstr3Lbl: Label '3. Apply silicone adhesive, cure 10 min', MaxLength = 50;
        ElectricalWiringDescLbl: Label 'Electrical wiring', MaxLength = 100;
        ElectricalWiringInstr1Lbl: Label '1. Route power cord through housing', MaxLength = 50;
        ElectricalWiringInstr2Lbl: Label '2. Solder connections per wiring diagram', MaxLength = 50;
        ElectricalWiringInstr3Lbl: Label '3. Verify continuity before closing', MaxLength = 50;
        TestingDescLbl: Label 'Quality testing', MaxLength = 100;
        PackingDescLbl: Label 'Product packaging', MaxLength = 100;
        PackingInstr1Lbl: Label '1. Insert product in protective foam', MaxLength = 50;
        PackingInstr2Lbl: Label '2. Add accessories and documentation', MaxLength = 50;
        PackingInstr3Lbl: Label '3. Seal box and apply label', MaxLength = 50;
        PaintingDescLbl: Label 'Painting and finishing', MaxLength = 100;
        PaintingInstr1Lbl: Label '1. Clean surface and apply primer', MaxLength = 50;
        PaintingInstr2Lbl: Label '2. Spray paint in ventilated cabin', MaxLength = 50;
        PaintingInstr3Lbl: Label '3. Dry for 30 min at room temperature', MaxLength = 50;
        PaintingInstr4Lbl: Label '4. Inspect finish quality', MaxLength = 50;
        SubcontractedAssemblyDescLbl: Label 'Subcontracted assembly', MaxLength = 100;
        FullSubcontractedProductionDescLbl: Label 'Full subcontracted production', MaxLength = 100;
}
