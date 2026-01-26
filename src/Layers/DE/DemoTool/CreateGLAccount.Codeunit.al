codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('0000', X0000, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0001', X0001, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0002', X0002, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0009', X0009, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0010', X0010, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0015', X0015, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0020', X0020, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0025', X0025, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0027', X0027, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0030', X0030, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0031', X0031, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0035', X0035, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0038', X0038, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0039', X0039, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0040', X0040, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0041', X0041, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0042', X0042, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0050', X0050, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0060', X0060, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0065', X0065, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0070', X0070, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0075', X0075, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0079', X0079, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0080', X0080, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0085', X0085, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0090', X0090, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0100', X0100, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0110', X0110, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0111', X0111, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0112', X0112, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0113', X0113, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0115', X0115, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0120', X0120, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0129', X0129, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0140', X0140, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0145', X0145, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0146', X0146, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0147', X0147, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0148', X0148, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0150', X0150, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0159', X0159, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0160', X0160, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0165', X0165, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0170', X0170, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0175', X0175, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0176', X0176, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0177', X0177, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0178', X0178, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0179', X0179, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0180', X0180, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0189', X0189, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0190', X0190, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0191', X0191, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0192', X0192, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0193', X0193, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0194', X0194, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0195', X0195, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0199', X0199, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0200', X0200, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0201', X0201, 3, 1, 0, '', 0, '', '', '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0210', X0210, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0220', X0220, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0240', X0240, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0260', X0260, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0280', X0280, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('0290', X0290, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0299', X0299, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0300', X0300, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0301', X0301, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0310', X0310, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0320', X0320, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('0350', X0350, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('0380', X0380, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0400', X0400, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0410', X0410, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0420', X0420, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0430', X0430, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0440', X0440, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0450', X0450, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0460', X0460, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0480', X0480, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0490', X0490, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0491', X0491, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0492', X0492, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('0495', X0495, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0497', X0497, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0501', X0501, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0502', X0502, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0503', X0503, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0504', X0504, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0505', X0505, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0509', X0509, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0510', X0510, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0513', X0513, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0516', X0516, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0517', X0517, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0518', X0518, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0519', X0519, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0520', X0520, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0522', X0522, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0525', X0525, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0530', X0530, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0535', X0535, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0540', X0540, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0550', X0550, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0570', X0570, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0580', X0580, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0590', X0590, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0594', X0594, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0595', X0595, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0596', X0596, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0599', X0599, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0600', X0600, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0602', X0602, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0604', X0604, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0605', X0605, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0610', X0610, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0614', X0614, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0615', X0615, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0616', X0616, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0620', X0620, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0624', X0624, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0626', X0626, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0627', X0627, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0630', X0630, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0633', X0633, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0635', X0635, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0640', X0640, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0650', X0650, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0659', X0659, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0660', X0660, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0661', X0661, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0670', X0670, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0680', X0680, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0685', X0685, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0698', X0698, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0700', X0700, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0701', X0701, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0705', X0705, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0710', X0710, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0714', X0714, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0715', X0715, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0716', X0716, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0720', X0720, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0725', X0725, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0729', X0729, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0730', X0730, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0731', X0731, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0740', X0740, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0750', X0750, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0755', X0755, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0759', X0759, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0760', X0760, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0761', X0761, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0764', X0764, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0767', X0767, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0769', X0769, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0770', X0770, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0771', X0771, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0774', X0774, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0777', X0777, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0779', X0779, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0780', X0780, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0781', X0781, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0784', X0784, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0787', X0787, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0788', X0788, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0789', X0789, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0790', X0790, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0799', X0799, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0800', X0800, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0801', X0801, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0810', X0810, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0820', X0820, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0830', X0830, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0838', X0838, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0839', X0839, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0840', X0840, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0841', X0841, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0842', X0842, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0843', X0843, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0844', X0844, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0845', X0845, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0846', X0846, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0847', X0847, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0848', X0848, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0850', X0850, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0851', X0851, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0852', X0852, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0853', X0853, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0854', X0854, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0855', X0855, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0856', X0856, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0857', X0857, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0858', X0858, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0860', X0860, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0862', X0862, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0864', X0864, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0865', X0865, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0866', X0866, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0867', X0867, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0868', X0868, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0869', X0869, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0871', X0871, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0872', X0872, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0873', X0873, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0880', X0880, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0882', X0882, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0889', X0889, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0899', X0899, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0900', X0900, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0910', X0910, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0920', X0920, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0928', X0928, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0929', X0929, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0930', X0930, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0931', X0931, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0932', X0932, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0933', X0933, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0934', X0934, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0935', X0935, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0936', X0936, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0937', X0937, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0938', X0938, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0939', X0939, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0940', X0940, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0941', X0941, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0942', X0942, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0943', X0943, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0944', X0944, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0945', X0945, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0946', X0946, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0947', X0947, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0948', X0948, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0949', X0949, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0950', X0950, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0955', X0955, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0957', X0957, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0963', X0963, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0969', X0969, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0970', X0970, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0971', X0971, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0972', X0972, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0973', X0973, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0974', X0974, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0976', X0976, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0977', X0977, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0978', X0978, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0979', X0979, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0980', X0980, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0983', X0983, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0984', X0984, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0985', X0985, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0986', X0986, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0990', X0990, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0991', X0991, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0992', X0992, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('0993', X0993, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0996', X0996, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0997', X0997, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('0998', X0998, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1000', X1000, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1002', X1002, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1005', X1005, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1010', X1010, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1015', X1015, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1019', X1019, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1100', X1100, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1110', X1110, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1120', X1120, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1130', X1130, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1140', X1140, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1190', X1190, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1195', X1195, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1199', X1199, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1200', X1200, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1210', X1210, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1220', X1220, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1230', X1230, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1290', X1290, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1299', X1299, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1300', X1300, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1301', X1301, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1302', X1302, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1305', X1305, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1310', X1310, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1311', X1311, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1312', X1312, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1315', X1315, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1320', X1320, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1321', X1321, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1322', X1322, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1325', X1325, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1327', X1327, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1328', X1328, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1330', X1330, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1331', X1331, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1339', X1339, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1340', X1340, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1341', X1341, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1342', X1342, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1343', X1343, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1344', X1344, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1345', X1345, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1349', X1349, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1350', X1350, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1352', X1352, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1355', X1355, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1360', X1360, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1370', X1370, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1380', X1380, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1390', X1390, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1391', X1391, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1400', X1400, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1401', X1401, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1402', X1402, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1403', X1403, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1410', X1410, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1451', X1451, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1455', X1455, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1456', X1456, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1460', X1460, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1461', X1461, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1465', X1465, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1469', X1469, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1470', X1470, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1471', X1471, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1475', X1475, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1477', X1477, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1478', X1478, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1479', X1479, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1480', X1480, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1481', X1481, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1485', X1485, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1487', X1487, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1488', X1488, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1489', X1489, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1490', X1490, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1491', X1491, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1495', X1495, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1497', X1497, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1498', X1498, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1499', X1499, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1500', X1500, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1501', X1501, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1502', X1502, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1503', X1503, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1504', X1504, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1505', X1505, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1506', X1506, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1507', X1507, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1508', X1508, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1509', X1509, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1510', X1510, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1511', StrSubstNo(X1511, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('1517', StrSubstNo(X1517, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('1521', X1521, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1524', X1524, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1525', X1525, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1526', X1526, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1527', X1527, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1529', X1529, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1530', X1530, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1531', X1531, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1537', X1537, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1538', X1538, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1540', X1540, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1542', X1542, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1543', X1543, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1545', X1545, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1547', X1547, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1548', X1548, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1549', X1549, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1559', X1559, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1560', X1560, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1561', StrSubstNo(X1561, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1562', X1562, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1565', StrSubstNo(X1565, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1567', X1567, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1568', StrSubstNo(X1568, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1569', X1569, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1570', X1570, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1571', StrSubstNo(X1571, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1572', X1572, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1573', StrSubstNo(X1573, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1575', StrSubstNo(X1575, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1577', X1577, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1578', X1578, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1579', StrSubstNo(X1579, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1580', X1580, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1581', X1581, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1582', X1582, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1584', X1584, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1586', X1586, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1588', X1588, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', 'EUST', true);
        InsertData('1590', X1590, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1591', X1591, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1592', X1592, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1593', X1593, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1594', X1594, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1595', X1595, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1596', X1596, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1598', X1598, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1600', X1600, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1601', X1601, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1602', X1602, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1603', X1603, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1610', X1610, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1625', X1625, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1626', X1626, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1628', X1628, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1629', X1629, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1630', X1630, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1631', X1631, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1635', X1635, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1638', X1638, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1639', X1639, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1640', X1640, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1641', X1641, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1645', X1645, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1648', X1648, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1649', X1649, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1650', X1650, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1651', X1651, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1655', X1655, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1657', X1657, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1658', X1658, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1659', X1659, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1660', X1660, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1661', X1661, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1680', X1680, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1690', X1690, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1700', X1700, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1701', X1701, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1702', X1702, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1703', X1703, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1704', X1704, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1705', X1705, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1706', X1706, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1707', X1707, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1708', X1708, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1709', X1709, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1710', X1710, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1711', StrSubstNo(X1711, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('1717', StrSubstNo(X1717, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('1719', X1719, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1720', X1720, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1721', X1721, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1722', X1722, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1729', X1729, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1730', X1730, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1731', X1731, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1732', X1732, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1733', X1733, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1734', X1734, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1735', X1735, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1736', X1736, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1737', X1737, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1738', X1738, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1739', X1739, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1740', X1740, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1741', X1741, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1742', X1742, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1743', X1743, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1744', X1744, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1745', X1745, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1746', X1746, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1747', X1747, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1748', X1748, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1749', X1749, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1750', X1750, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1751', X1751, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1752', X1752, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1753', X1753, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1755', X1755, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1756', X1756, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1757', X1757, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1758', StrSubstNo(X1758, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1760', X1760, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1761', StrSubstNo(X1761, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1762', X1762, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1763', StrSubstNo(X1763, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1765', StrSubstNo(X1765, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1767', X1767, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1768', X1768, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1771', StrSubstNo(X1771, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1772', X1772, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1773', StrSubstNo(X1773, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1775', StrSubstNo(X1775, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1777', X1777, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1778', StrSubstNo(X1778, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1779', X1779, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1780', X1780, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1781', X1781, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1782', X1782, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1783', X1783, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1784', X1784, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1785', X1785, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1786', StrSubstNo(X1786, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1788', X1788, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1789', X1789, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1790', X1790, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1791', X1791, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1792', X1792, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('1798', X1798, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('1799', X1799, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('1800', X1800, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1810', X1810, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1820', X1820, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1830', X1830, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1840', X1840, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1850', X1850, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1860', X1860, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1870', X1870, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1880', X1880, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1890', X1890, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1898', X1898, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('1899', X1899, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('1900', X1900, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1910', X1910, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1920', X1920, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1930', X1930, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1940', X1940, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1950', X1950, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1960', X1960, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1970', X1970, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1980', X1980, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1990', X1990, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('1998', X1998, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('1999', X1999, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2000', X2000, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('2001', X2001, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2005', X2005, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2008', X2008, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2009', X2009, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2010', X2010, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2020', X2020, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2099', X2099, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2100', X2100, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2107', X2107, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2108', X2108, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2109', X2109, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2110', X2110, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2114', X2114, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2115', X2115, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2116', X2116, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2118', X2118, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2119', X2119, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2120', X2120, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2126', X2126, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2127', X2127, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2129', X2129, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2130', X2130, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2139', X2139, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2140', X2140, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2149', X2149, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2150', X2150, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2160', X2160, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2165', X2165, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2166', X2166, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2167', X2167, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2170', X2170, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2171', StrSubstNo(X2171, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2175', StrSubstNo(X2175, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2177', X2177, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2199', X2199, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2200', X2200, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2203', X2203, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2208', X2208, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2209', X2209, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2210', X2210, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2212', X2212, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2213', X2213, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2215', X2215, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2218', X2218, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2223', X2223, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2280', X2280, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2282', X2282, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2284', X2284, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2285', X2285, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2287', X2287, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2289', X2289, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2298', X2298, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2300', X2300, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2307', X2307, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2309', X2309, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2310', X2310, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2311', X2311, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2312', X2312, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2313', X2313, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2315', X2315, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2318', X2318, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2320', X2320, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2323', X2323, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2325', X2325, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2340', X2340, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2341', X2341, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2345', X2345, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2347', X2347, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2348', X2348, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2349', X2349, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2350', X2350, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2375', X2375, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2380', X2380, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2381', X2381, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2382', X2382, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2383', X2383, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2384', X2384, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2385', X2385, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2386', X2386, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2387', X2387, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2388', X2388, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2389', X2389, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2400', X2400, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2401', StrSubstNo(X2401, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('2402', X2402, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('2403', StrSubstNo(X2403, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('2404', StrSubstNo(X2404, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('2405', StrSubstNo(X2405, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('2430', X2430, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2450', X2450, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2451', X2451, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2460', X2460, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2489', X2489, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2490', X2490, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2491', X2491, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2492', X2492, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2493', X2493, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2494', X2494, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2495', X2495, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2496', X2496, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2497', X2497, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2498', X2498, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2499', X2499, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2500', X2500, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2501', X2501, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2502', X2502, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2505', X2505, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2508', X2508, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2509', X2509, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2510', X2510, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2520', X2520, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2521', X2521, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2599', X2599, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2600', X2600, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2601', X2601, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2602', X2602, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2603', X2603, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2604', X2604, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2605', X2605, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2620', X2620, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2621', X2621, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2622', X2622, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2625', X2625, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2626', X2626, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2649', X2649, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2650', X2650, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('2655', X2655, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2656', X2656, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2657', X2657, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2658', X2658, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2659', X2659, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2660', X2660, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2662', X2662, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2665', X2665, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2666', X2666, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2670', X2670, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2679', X2679, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2680', X2680, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2685', X2685, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2686', X2686, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2695', X2695, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2699', X2699, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2700', X2700, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2705', X2705, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2707', X2707, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2709', X2709, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2710', X2710, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2711', X2711, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2712', X2712, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2713', X2713, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2714', X2714, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2715', X2715, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2716', X2716, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2720', X2720, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2723', X2723, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2725', X2725, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2730', X2730, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2731', X2731, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2732', X2732, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2734', X2734, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2735', X2735, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2736', X2736, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2737', X2737, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2738', X2738, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2739', X2739, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2740', X2740, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2741', X2741, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2742', X2742, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2743', X2743, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2744', X2744, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2745', X2745, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2750', X2750, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2790', X2790, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2792', X2792, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2794', X2794, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2795', X2795, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2796', X2796, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2797', X2797, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2798', X2798, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2799', X2799, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2800', X2800, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2860', X2860, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2862', X2862, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2864', X2864, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2866', X2866, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2868', X2868, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2869', X2869, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2870', X2870, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2879', X2879, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2889', X2889, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2890', X2890, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2891', X2891, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2892', X2892, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2893', X2893, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2894', X2894, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2895', X2895, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2990', X2990, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('2996', X2996, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('2999', X2999, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3000', X3000, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3090', X3090, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3099', X3099, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3100', X3100, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3110', StrSubstNo(X3110, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3115', StrSubstNo(X3115, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3120', StrSubstNo(X3120, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3125', StrSubstNo(X3125, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3130', StrSubstNo(X3130, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3135', StrSubstNo(X3135, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3140', StrSubstNo(X3140, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3145', StrSubstNo(X3145, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3150', X3150, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3200', X3200, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3300', StrSubstNo(X3300, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3400', StrSubstNo(X3400, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3420', StrSubstNo(X3420, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3425', StrSubstNo(X3425, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3430', StrSubstNo(X3430, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3435', StrSubstNo(X3435, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData('3550', X3550, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('3559', X3559, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('3598', X3598, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3600', X3600, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3610', StrSubstNo(X3610, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3650', StrSubstNo(X3650, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3698', X3698, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3700', X3700, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3710', StrSubstNo(X3710, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3720', StrSubstNo(X3720, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3724', StrSubstNo(X3724, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3725', StrSubstNo(X3725, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3726', X3726, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3728', X3728, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3729', X3729, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3730', X3730, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3731', StrSubstNo(X3731, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3732', StrSubstNo(X3732, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3733', X3733, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('3734', X3734, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('3736', X3736, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('3737', X3737, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3740', X3740, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3750', StrSubstNo(X3750, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3760', StrSubstNo(X3760, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3765', X3765, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3770', X3770, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3780', StrSubstNo(X3780, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('3790', StrSubstNo(X3790, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('3795', X3795, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3796', X3796, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3799', X3799, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3800', X3800, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('3830', X3830, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('3850', X3850, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3960', X3960, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3965', X3965, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3969', X3969, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3970', X3970, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3975', X3975, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3976', X3976, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3980', X3980, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3981', X3981, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3982', X3982, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3983', X3983, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3984', X3984, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3985', X3985, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3986', X3986, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3987', X3987, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3988', X3988, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3989', X3989, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3990', X3990, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('3998', X3998, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('3999', X3999, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4000', X4000, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4090', X4090, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4091', X4091, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4092', X4092, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4093', X4093, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4097', X4097, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4098', X4098, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4099', X4099, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4100', X4100, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4110', X4110, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4120', X4120, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4124', X4124, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4125', X4125, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4126', X4126, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4127', X4127, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4130', X4130, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4137', X4137, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4138', X4138, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4139', X4139, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4140', X4140, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4145', X4145, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4149', X4149, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4150', X4150, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4160', X4160, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4165', X4165, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4169', X4169, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4170', X4170, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4175', X4175, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4180', X4180, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4190', X4190, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4197', X4197, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4198', X4198, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4199', X4199, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4204', X4204, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4205', X4205, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4210', X4210, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4218', X4218, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4220', X4220, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('4228', X4228, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4230', X4230, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4240', X4240, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4250', X4250, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4260', X4260, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4270', X4270, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4280', X4280, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4300', X4300, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4301', StrSubstNo(X4301, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4305', StrSubstNo(X4305, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4320', X4320, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4340', X4340, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4350', X4350, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4360', X4360, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4380', X4380, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4390', X4390, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4500', X4500, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4510', X4510, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4520', X4520, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4530', X4530, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4540', X4540, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4550', X4550, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4570', X4570, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4580', X4580, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4600', X4600, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4610', X4610, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4630', X4630, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4635', X4635, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4638', X4638, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4640', X4640, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4650', X4650, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4653', X4653, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4654', X4654, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4655', X4655, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4660', X4660, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4670', X4670, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4700', X4700, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4710', X4710, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4730', X4730, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4750', X4750, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4760', X4760, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4780', X4780, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4790', X4790, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4800', X4800, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4805', X4805, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4809', X4809, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4810', X4810, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4811', X4811, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4812', X4812, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4813', X4813, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4814', X4814, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4815', X4815, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4820', X4820, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4821', X4821, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4822', X4822, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4824', X4824, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4826', X4826, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4830', X4830, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4840', X4840, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4850', X4850, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4855', X4855, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4860', X4860, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4865', X4865, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4868', X4868, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4869', X4869, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4870', X4870, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4871', X4871, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4872', X4872, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4873', X4873, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4874', X4874, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4875', X4875, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4876', X4876, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4877', X4877, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4878', X4878, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4879', X4879, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4880', X4880, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4881', X4881, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('4882', X4882, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4883', X4883, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4884', X4884, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('4885', X4885, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4886', X4886, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4887', X4887, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4890', X4890, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4900', X4900, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4905', X4905, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4910', X4910, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4920', X4920, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4925', X4925, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4930', X4930, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4940', X4940, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4945', X4945, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4946', X4946, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4948', X4948, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('4950', X4950, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('4955', X4955, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('4957', X4957, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4960', X4960, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4965', X4965, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4966', X4966, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4968', X4968, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4969', X4969, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4970', X4970, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4975', X4975, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4976', X4976, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4980', X4980, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4985', X4985, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('4986', X4986, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4988', X4988, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4989', X4989, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4990', X4990, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4991', X4991, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4992', X4992, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4993', X4993, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4994', X4994, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4995', X4995, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('4996', X4996, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4997', X4997, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4998', X4998, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('4999', X4999, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5000', X5000, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5001', X5001, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5002', X5002, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5003', X5003, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5004', X5004, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5005', X5005, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5010', X5010, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5089', X5089, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5090', X5090, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5091', X5091, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5092', X5092, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5093', X5093, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5094', X5094, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('5100', X5100, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('5999', X5999, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('7000', X7000, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('7050', X7050, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('7080', X7080, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('7090', X7090, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('7095', X7095, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('7099', X7099, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('7100', X7100, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('7110', X7110, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('7120', X7120, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('7130', X7130, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('7140', X7140, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('7149', X7149, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8000', X8000, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8099', X8099, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8100', X8100, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8110', X8110, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8120', X8120, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8125', X8125, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8128', X8128, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8130', X8130, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8140', X8140, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8150', X8150, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8196', StrSubstNo(X8196, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8199', X8199, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8200', X8200, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8300', StrSubstNo(X8300, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8310', StrSubstNo(X8310, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8315', StrSubstNo(X8315, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8320', X8320, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8338', X8338, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8339', X8339, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8400', StrSubstNo(X8400, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8405', X8405, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8450', X8450, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8451', X8451, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8452', X8452, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8460', X8460, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8500', X8500, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8505', X8505, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8506', StrSubstNo(X8506, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8508', StrSubstNo(X8508, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8509', X8509, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8511', X8511, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8515', X8515, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8520', X8520, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8530', X8530, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8540', X8540, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8549', X8549, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8550', X8550, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8589', X8589, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8590', X8590, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8591', StrSubstNo(X8591, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8595', StrSubstNo(X8595, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8600', X8600, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8610', X8610, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8611', StrSubstNo(X8611, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8620', X8620, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8625', X8625, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8630', StrSubstNo(X8630, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8640', StrSubstNo(X8640, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '', '', true);
        InsertData('8645', X8645, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8649', X8649, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8650', X8650, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8660', X8660, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8699', X8699, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8700', X8700, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8705', X8705, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8710', StrSubstNo(X8710, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8720', StrSubstNo(X8720, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8725', StrSubstNo(X8725, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8726', StrSubstNo(X8726, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8730', X8730, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8731', StrSubstNo(X8731, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8732', StrSubstNo(X8732, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8733', X8733, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8734', X8734, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8735', X8735, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8737', X8737, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8740', X8740, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8750', StrSubstNo(X8750, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8760', StrSubstNo(X8760, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8765', X8765, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8770', X8770, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8780', StrSubstNo(X8780, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8790', StrSubstNo(X8790, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8791', X8791, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8795', X8795, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8798', X8798, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8800', X8800, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8801', StrSubstNo(X8801, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8807', X8807, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8808', X8808, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8809', StrSubstNo(X8809, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8817', X8817, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8818', X8818, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8819', X8819, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8820', StrSubstNo(X8820, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('8827', X8827, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8828', X8828, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8829', X8829, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8837', X8837, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8838', X8838, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8839', X8839, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8840', X8840, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8900', X8900, 3, 0, 0, '', 2, '', '', '', '', false);
        InsertData('8905', X8905, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.NoVATCode(), true);
        InsertData('8910', StrSubstNo(X8910, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8915', StrSubstNo(X8915, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8916', X8916, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8919', X8919, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8920', X8920, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8921', StrSubstNo(X8921, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8930', StrSubstNo(X8930, DemoDataSetup.ServicesVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode(), true);
        InsertData('8935', X8935, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8939', X8939, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8940', X8940, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8941', StrSubstNo(X8941, DemoDataSetup.GoodsVATText()), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8945', X8945, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8949', X8949, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('8950', X8950, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8955', X8955, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8956', X8956, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8959', X8959, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8960', X8960, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8970', X8970, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8975', X8975, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8977', X8977, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8980', X8980, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8988', X8988, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8989', X8989, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('8990', X8990, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8995', X8995, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('9000', X9000, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9001', X9001, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9008', X9008, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9009', X9009, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9060', X9060, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9069', X9069, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9070', X9070, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9071', X9071, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9072', X9072, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9073', X9073, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9074', X9074, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9075', X9075, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9076', X9076, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9077', X9077, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9078', X9078, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9085', X9085, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9086', X9086, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9087', X9087, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9088', X9088, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9089', X9089, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9090', X9090, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9091', X9091, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9092', X9092, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9093', X9093, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9094', X9094, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9095', X9095, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9096', X9096, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9097', X9097, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9098', X9098, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9099', X9099, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9100', X9100, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9101', X9101, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9102', X9102, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9103', X9103, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9104', X9104, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9105', X9105, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9106', X9106, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9107', X9107, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9108', X9108, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9109', X9109, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9110', X9110, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9116', X9116, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9117', X9117, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9118', X9118, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9120', X9120, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9190', X9190, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9199', X9199, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9200', X9200, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9209', X9209, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9210', X9210, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9219', X9219, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9220', X9220, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9221', X9221, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9222', X9222, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9229', X9229, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9230', X9230, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9231', X9231, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9232', X9232, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9234', X9234, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9239', X9239, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9240', X9240, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9241', X9241, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9242', X9242, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9243', X9243, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9244', X9244, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9245', X9245, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9246', X9246, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9247', X9247, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9249', X9249, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9250', X9250, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9251', X9251, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9255', X9255, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9259', X9259, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9260', X9260, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9261', X9261, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9262', X9262, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9264', X9264, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9268', X9268, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9269', X9269, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9270', X9270, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9271', X9271, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9272', X9272, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9273', X9273, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9274', X9274, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9275', X9275, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9276', X9276, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9277', X9277, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9278', X9278, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9279', X9279, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9280', X9280, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9281', X9281, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9282', X9282, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9283', X9283, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9284', X9284, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9290', X9290, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9291', X9291, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9292', X9292, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9293', X9293, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9410', X9410, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9411', X9411, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9413', X9413, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9415', X9415, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9416', X9416, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9420', X9420, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9421', X9421, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9422', X9422, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9426', X9426, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9427', X9427, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9428', X9428, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9429', X9429, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9430', X9430, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9431', X9431, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9432', X9432, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9433', X9433, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9434', X9434, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9435', X9435, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9436', X9436, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9438', X9438, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9440', X9440, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9445', X9445, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9446', X9446, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9447', X9447, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9448', X9448, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9449', X9449, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9450', X9450, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9451', X9451, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9452', X9452, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9453', X9453, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9454', X9454, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9455', X9455, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9456', X9456, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9457', X9457, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9458', X9458, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9459', X9459, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9460', X9460, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9462', X9462, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9463', X9463, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9464', X9464, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9465', X9465, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9467', X9467, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9468', X9468, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9469', X9469, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9470', X9470, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9472', X9472, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9473', X9473, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9474', X9474, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9475', X9475, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9476', X9476, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9477', X9477, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9478', X9478, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9479', X9479, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9480', X9480, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9481', X9481, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9482', X9482, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9486', X9486, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9487', X9487, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9499', X9499, 1, 1, 0, '', 0, '', '', '', '', false);
        InsertData('9500', X9500, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9510', X9510, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9520', X9520, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9530', X9530, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9540', X9540, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9570', X9570, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9580', X9580, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9590', X9590, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9600', X9600, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9610', X9610, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9620', X9620, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9630', X9630, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9640', X9640, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('9650', X9650, 0, 1, 0, '', 0, '', '', '', '', true);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccIndent: Codeunit "G/L Account-Indent";
        X0000: Label 'Chart of accounts SKR03';
        X0001: Label 'Exp. for start-up or expansion of bus. operations';
        X0002: Label 'Expenses for switching to Euro';
        X0009: Label 'Intangible assets';
        X0010: Label 'Concessions and property rights';
        X0015: Label 'Concessions';
        X0020: Label 'Industrial property rights';
        X0025: Label 'Similar rights and values';
        X0027: Label 'EDV-Software';
        X0030: Label 'Licenses to property rights';
        X0031: Label 'Total concessions & property rights';
        X0035: Label 'Goodwill or company value';
        X0038: Label 'Pre-payments on account of goodwill or bus. value';
        X0039: Label 'Pre-payments on account of intangible assets';
        X0040: Label 'Merger surplus';
        X0041: Label 'Total intangible assets';
        X0042: Label 'Property, plant and equipment';
        X0050: Label 'Land and buildings';
        X0060: Label 'Undeveloped land';
        X0065: Label 'Undeveloped land';
        X0070: Label 'Leasehold rights';
        X0075: Label 'Land subject to amortization';
        X0079: Label 'Total undeveloped land';
        X0080: Label 'Buildings on own land';
        X0085: Label 'Value of developed land';
        X0090: Label 'Commercial buildings';
        X0100: Label 'Factory buildings';
        X0110: Label 'Garages';
        X0111: Label 'Outdoor facilities';
        X0112: Label 'Sealed courtyards and roads';
        X0113: Label 'Fit-out for business premises and factories';
        X0115: Label 'Other buildings';
        X0120: Label 'Buildings under construction';
        X0129: Label 'Pre-payments on account of buildings on own land';
        X0140: Label 'Residential buildings';
        X0145: Label 'Garages';
        X0146: Label 'Outside facilities';
        X0147: Label 'Sealed courtyards and roads';
        X0148: Label 'Fixtures in residential buildings';
        X0150: Label 'Residential buildings under construction';
        X0159: Label 'Total buildings on own land';
        X0160: Label 'Buildings on third-party land';
        X0165: Label 'Commercial buildings';
        X0170: Label 'Factory buildings';
        X0175: Label 'Garages';
        X0176: Label 'Outside facilities';
        X0177: Label 'Sealed courtyards and roads';
        X0178: Label 'Fixtures in commercial/industrial buildings';
        X0179: Label 'Other buildings';
        X0180: Label 'Buildings under construction';
        X0189: Label 'Advance payments for buildings';
        X0190: Label 'Residential buildings';
        X0191: Label 'Garages';
        X0192: Label 'Outside facilities';
        X0193: Label 'Sealed courtyards and roads';
        X0194: Label 'Fixtures in residential buildings';
        X0195: Label 'Residential buildings under construction';
        X0199: Label 'Total buildings on third-party land';
        X0200: Label 'Total land and buildings';
        X0201: Label 'Technical plant and machinery';
        X0210: Label 'Machinery';
        X0220: Label 'Machinery-related tools';
        X0240: Label 'Machine facilities';
        X0260: Label 'Transport facilities & similar';
        X0280: Label 'Operational equipment';
        X0290: Label 'Technical plants/machines under construction';
        X0299: Label 'Technical plants/machines';
        X0300: Label 'Total technical systems';
        X0301: Label 'Other plant/equipment';
        X0310: Label 'Other equipment';
        X0320: Label 'Cars';
        X0350: Label 'Trucks';
        X0380: Label 'Other transport equipment';
        X0400: Label 'Operational equipment';
        X0410: Label 'Business equipment';
        X0420: Label 'Office equipment';
        X0430: Label 'Shop fit-out';
        X0440: Label 'Tools';
        X0450: Label 'Installations';
        X0460: Label 'Scaffolding/formwork materials';
        X0480: Label 'Low-value assets up to 800 EUR';
        X0490: Label 'Other operations/business equipment';
        X0491: Label 'Plant & equipment under construction';
        X0492: Label 'Advance payments on plant & equipment';
        X0495: Label 'Total other plant/operational equipment';
        X0497: Label 'Total property, plant and equipment';
        X0501: Label 'Financial assets';
        X0502: Label 'Participating interests';
        X0503: Label 'Interests in affiliated companies';
        X0504: Label 'Majority interests in associated companies';
        X0505: Label 'Lendings to affiliated companies';
        X0509: Label 'Total participating interests';
        X0510: Label 'Participating interests';
        X0513: Label 'Typical silent partnerships';
        X0516: Label 'Atypical silent partnerships';
        X0517: Label 'Other participating interests in stock corp.';
        X0518: Label 'Other participating interests in private companies';
        X0519: Label 'Participating interests GmbH & Co.KG in Komp.GmbH';
        X0520: Label 'Lendings to associated companies';
        X0522: Label 'Total participating interests';
        X0525: Label 'Non-current securities';
        X0530: Label 'Securities with profit share';
        X0535: Label 'Fixed-interest securities';
        X0540: Label 'Other lendings';
        X0550: Label 'Loans';
        X0570: Label 'Non-current shares in cooperatives';
        X0580: Label 'Loans to shareholders';
        X0590: Label 'Loans to related parties';
        X0594: Label 'Reinsurance cover from life insurance';
        X0595: Label 'Total non-current securities';
        X0596: Label 'Total financial assets';
        X0599: Label 'Liabilities';
        X0600: Label 'Bond liabilities';
        X0602: Label 'Non-convertible bonds';
        X0604: Label 'Remaining term up to 1 year';
        X0605: Label 'Remaining term 1-5 years';
        X0610: Label 'Remaining term more than 5 years';
        X0614: Label 'Total non-convertible bonds';
        X0615: Label 'Convertible bonds';
        X0616: Label 'Remaining term up to 1 year';
        X0620: Label 'Remaining term 1-5 years';
        X0624: Label 'Remaining term more than 5 years';
        X0626: Label 'Total convertible bonds';
        X0627: Label 'Total bond liabilities';
        X0630: Label 'Liabilities to banks';
        X0633: Label 'Liabilities';
        X0635: Label 'Remaining term up to 1 year';
        X0640: Label 'Remaining term 1-5 years';
        X0650: Label 'Remaining term more than 5 years';
        X0659: Label 'Total liabilities';
        X0660: Label 'Liabilities from contr. with payment instalments';
        X0661: Label 'Remaining term up to 1 year';
        X0670: Label 'Remaining term 1-5 years';
        X0680: Label 'Remaining term more than 5 years';
        X0685: Label 'Total liabilities from contr. with paym. instalm.';
        X0698: Label 'Total liabilities to banks';
        X0700: Label 'Liabilities to affiliated companies';
        X0701: Label 'Remaining term up to 1 year';
        X0705: Label 'Remaining term 1-5 years';
        X0710: Label 'Remaining term more than 5 years';
        X0714: Label 'Total liabilities to affiliated companies';
        X0715: Label 'Liabilities to associated companies';
        X0716: Label 'Remaining term up to 1 year';
        X0720: Label 'Remaining term 1-5 years';
        X0725: Label 'Remaining term more than 5 years';
        X0729: Label 'Total liabilities to associated companies';
        X0730: Label 'Liabilities to shareholders';
        X0731: Label 'Remaining term up to 1 year';
        X0740: Label 'Remaining term 1-5 years';
        X0750: Label 'Remaining term more than 5 years';
        X0755: Label 'Liabil. to shareholders for undisbursed distrib.';
        X0759: Label 'Total liabilities to shareholders';
        X0760: Label 'Loans typical silent shareholder';
        X0761: Label 'Remaining term up to 1 year';
        X0764: Label 'Remaining term 1-5 years';
        X0767: Label 'Remaining term more than 5 years';
        X0769: Label 'Total loans typical silent shareholders';
        X0770: Label 'Loans atypical silent shareholders';
        X0771: Label 'Remaining term up to 1 year';
        X0774: Label 'Remaining term 1-5 years';
        X0777: Label 'Remaining term more than 5 years';
        X0779: Label 'Total loans of atypical silent shareholders';
        X0780: Label 'Shareholder loans';
        X0781: Label 'Remaining term up to 1 year';
        X0784: Label 'Remaining term 1-5 years';
        X0787: Label 'Remaining term more than 5 years';
        X0788: Label 'Total other liabilities';
        X0789: Label 'Total liabilities';
        X0790: Label 'Equity stock corporation';
        X0799: Label 'Subscribed capital';
        X0800: Label 'Subscribed capital';
        X0801: Label 'Outstanding capital contributions unclaimed';
        X0810: Label 'Due deposits claimed';
        X0820: Label 'Due deposits not claimed (P)';
        X0830: Label 'Due deposits claimed (P)';
        X0838: Label 'Claimed subsequent capital contribution';
        X0839: Label 'Total subscribed capital';
        X0840: Label 'Capital reserves';
        X0841: Label 'Capital res. by issuance of shares > nominal value';
        X0842: Label 'Cap. res. by iss. of bonds/opt. rights for shares';
        X0843: Label 'Cap. res. by granting prefer. rights to shares';
        X0844: Label 'Total capital reserves';
        X0845: Label 'Retained earnings';
        X0846: Label 'Compulsory reserves';
        X0847: Label 'Compulsory reserves 40% reserved';
        X0848: Label 'Compulsory reserves 0% reserved (EK04)';
        X0850: Label 'Reserves for treasury shares';
        X0851: Label 'Statutory reserves';
        X0852: Label 'Reserves 40% reserved';
        X0853: Label 'Reserves 0% reserved';
        X0854: Label 'Reserves 0% reserved (EK02)';
        X0855: Label 'Other retained earnings';
        X0856: Label 'Equity share appreciation in value';
        X0857: Label 'Other retained earnings';
        X0858: Label 'Other retained earnings 0% reserved';
        X0860: Label 'Profit/loss before appropriation';
        X0862: Label 'Profits carried forward 40% reserved';
        X0864: Label 'Profits carried forward 0% reserved';
        X0865: Label 'Profits carried forward 0% reserved (EK02)';
        X0866: Label 'Losses before appropriation';
        X0867: Label 'Carryforwards to new financial year';
        X0868: Label 'Total retained earnings';
        X0869: Label 'Total equity stock corporation';
        X0871: Label 'Equity private company';
        X0872: Label 'Personally liable partners';
        X0873: Label 'Fixed capital';
        X0880: Label 'Variable capital';
        X0882: Label 'Shareholder loans';
        X0889: Label 'Total personally liable partners';
        X0899: Label 'Limited partners';
        X0900: Label 'Limited partner capital';
        X0910: Label 'Loss settlement account';
        X0920: Label 'Shareholder loans';
        X0928: Label 'Total limited partners';
        X0929: Label 'Total capital private companies';
        X0930: Label 'Special item with reserves';
        X0931: Label 'Special item purs. to § 6b EStG';
        X0932: Label 'Special item purs. to Abs. 35 EStR';
        X0933: Label 'Special item purs. to § 6d EStG';
        X0934: Label 'Special item purs. to § 1 EntwLStG';
        X0935: Label 'Special item from switch to Euro';
        X0936: Label 'Special item with reserves § 7d EStG';
        X0937: Label 'Special item with reserves § 79 EStDV';
        X0938: Label 'Special item with reserves § 80 EStDV';
        X0939: Label 'Special item purs. to § 52 Abs.16 EStG';
        X0940: Label 'Special item with reserves unsched. amort.';
        X0941: Label 'Special item purs. to § 82a EStDV';
        X0942: Label 'Special item purs. to § 82d EStDV';
        X0943: Label 'Special item purs. to § 82e EStDV';
        X0944: Label 'Special item purs. to § 14 BerlinFG';
        X0945: Label 'Special item purs. to § 3 ZonenRFG';
        X0946: Label 'Special item purs. to § 4d EStG';
        X0947: Label 'Special item purs. to § 7g Abs.1 EStG';
        X0948: Label 'Total special items with reserve amount';
        X0949: Label 'Provisions';
        X0950: Label 'Provisions for pensions and similar';
        X0955: Label 'Provisions for taxes';
        X0957: Label 'Provisions for trade tax';
        X0963: Label 'Provisions for corporate income tax';
        X0969: Label 'Provisions for deferred tax liabilities';
        X0970: Label 'Other provisions';
        X0971: Label 'Deferred expenses for maintenance, 3 months';
        X0972: Label 'Deferred expenses for maintenance, 4-12';
        X0973: Label 'Provisions for disposal of excavation/waste';
        X0974: Label 'Provisions for warranty claims';
        X0976: Label 'Provisions for impending losses';
        X0977: Label 'Provisions for accounting and auditing';
        X0978: Label 'Total provisions';
        X0979: Label 'Deferral/accrual item';
        X0980: Label 'Accrued income';
        X0983: Label 'Accrual of deferred tax assets';
        X0984: Label 'Customs levies and consumption taxes (expense)';
        X0985: Label 'VAT on advance payments (expense)';
        X0986: Label 'Debt discount/disagio';
        X0990: Label 'Deferred expenses';
        X0991: Label 'Total deferral and accruals';
        X0992: Label 'Impairment';
        X0993: Label 'Impairments';
        X0996: Label 'Lumpsum bad debt allowance for receivab. < 1 year';
        X0997: Label 'Lumpsum bad debt allowance for receivab. > 1 year';
        X0998: Label 'Total impairments';
        X1000: Label 'Checks, cash, bank balances';
        X1002: Label 'Cash at hand';
        X1005: Label 'Cash at hand';
        X1010: Label 'Petty cash 1';
        X1015: Label 'Petty cash 2';
        X1019: Label 'Total cash';
        X1100: Label 'Postbank';
        X1110: Label 'Postbank 1';
        X1120: Label 'Postbank 2';
        X1130: Label 'Postbank 3';
        X1140: Label 'Accumulated disposals, buildings';
        X1190: Label 'Balance with state central bank';
        X1195: Label 'Balance with Bundesbank';
        X1199: Label 'Total Postbank';
        X1200: Label 'Bank';
        X1210: Label 'Bank 1';
        X1220: Label 'Bank 2';
        X1230: Label 'Bank 3';
        X1290: Label 'Financial assets for short-term cash management';
        X1299: Label 'Total bank';
        X1300: Label 'Bills of Exchange from deliveries/services';
        X1301: Label ' - Remaining term up to 1 year';
        X1302: Label ' - Remaining term more than 1 year';
        X1305: Label ' - Rediscountable';
        X1310: Label 'Change of ownership affiliated company';
        X1311: Label ' - Remaining term up to 1 year';
        X1312: Label ' - Remaining term more than 1 year';
        X1315: Label ' - Rediscountable';
        X1320: Label 'Change of ownership, ownership structure';
        X1321: Label ' - Remaining term up to 1 year';
        X1322: Label ' - Remaining term more than 1 year';
        X1325: Label '#NAME?';
        X1327: Label 'Finance bills';
        X1328: Label 'Other securities w/ insignif. price fluctuation';
        X1330: Label 'Checks';
        X1331: Label 'Total checks,cash,bank balances';
        X1339: Label 'Securities';
        X1340: Label 'Shares in affiliated companies (in circulation)';
        X1341: Label 'Majority interests in associated companies';
        X1342: Label 'Treasury shares';
        X1343: Label 'Other securities';
        X1344: Label 'Securities for short-term cash management';
        X1345: Label 'Total securities';
        X1349: Label 'Receivables and other assets';
        X1350: Label 'Interest in GmbH held short-term';
        X1352: Label 'Shares in cooperatives held short term';
        X1355: Label 'Claims against reinsurance';
        X1360: Label 'Funds in transit';
        X1370: Label 'Profits offset § 4/3 EStG';
        X1380: Label 'Transition account cost center';
        X1390: Label 'Actual tax offset';
        X1391: Label 'Total trade receivables and other assets';
        X1400: Label 'Trade receivables';
        X1401: Label 'Trade receivables domestic';
        X1402: Label 'Trade receivables other countries';
        X1403: Label 'Intercompany receivables';
        X1410: Label 'without current account';
        X1451: Label 'Remaining term up to 1 year';
        X1455: Label 'Remaining term more than 1 year';
        X1456: Label 'Total excluding current account';
        X1460: Label 'Doubtful receivables';
        X1461: Label 'Remaining term up to 1 year';
        X1465: Label 'Remaining term more than 1 year';
        X1469: Label 'Total doubtful receivables';
        X1470: Label 'from affiliated companies';
        X1471: Label 'Remaining term up to 1 year';
        X1475: Label 'Remaining term more than 1 year';
        X1477: Label 'Bad debt allowance remaining term up to 1 year';
        X1478: Label 'Bad debt allowance remaining term > 1 year';
        X1479: Label 'Total receivables from affiliated companies';
        X1480: Label 'Total receivables from associated companies';
        X1481: Label 'Remaining term up to 1 year';
        X1485: Label 'Remaining term more than 1 year';
        X1487: Label 'Bad debt allowance remaining term up to 1 year';
        X1488: Label 'Bad debt allowance remaining term > 1 year';
        X1489: Label 'Total receivables from associated companies';
        X1490: Label 'from shareholders';
        X1491: Label 'Remaining term up to 1 year';
        X1495: Label 'Remaining term more than 1 year';
        X1497: Label 'Contra account other assets debtor';
        X1498: Label 'Total receivables from shareholders';
        X1499: Label 'Total receivables';
        X1500: Label 'Other assets';
        X1501: Label 'Remaining term up to 1 year';
        X1502: Label 'Remaining term more than 1 year';
        X1503: Label 'Receivables from exec. board/CEO <1 year';
        X1504: Label 'Receivables from exec. board/CEO >1 year';
        X1505: Label 'Receivables supervisory board/board member <1';
        X1506: Label 'Receivables supervisory board/board member >1';
        X1507: Label 'Receivables associate <1 year';
        X1508: Label 'Receivables from shareholders >1 year';
        X1509: Label 'Total other assets';
        X1510: Label 'Advance payments on account of inventories';
        X1511: Label 'Advance payments %1 VAT';
        X1517: Label 'Advance payments %1 VAT';
        X1521: Label 'Agency goods account';
        X1524: Label 'Total advance payments on account of inventories';
        X1525: Label 'Security deposits';
        X1526: Label 'Remaining term up to 1 year';
        X1527: Label 'Remaining term more than 1 year';
        X1529: Label 'Total security deposits';
        X1530: Label 'Receivables from employees';
        X1531: Label 'Remaining term up to 1 year';
        X1537: Label 'Remaining term more than 1 year';
        X1538: Label 'Total receivables from employees';
        X1540: Label 'Overpayment of taxes';
        X1542: Label 'Tax refund claims EU';
        X1543: Label 'Receivables from tax office for building tax disc.';
        X1545: Label 'VAT receivables';
        X1547: Label 'Receivables from consumption taxes paid';
        X1548: Label 'Consumption tax input next FY';
        X1549: Label 'Claim corporation income tax refund';
        X1559: Label 'Total overpayment of taxes';
        X1560: Label 'VAT to be apportioned';
        X1561: Label 'VAT to be apportioned %1';
        X1562: Label 'VAT to be apportioned EU';
        X1565: Label 'VAT to be apportioned %1';
        X1567: Label 'VAT to be apportioned (§13b UStG)';
        X1568: Label 'VAT to be apportioned %1 (§13b UStG)';
        X1569: Label 'Total VAT to be apportioned';
        X1570: Label 'Input credit VAT';
        X1571: Label 'Input credit VAT %1';
        X1572: Label 'Input credit VAT EU purchases';
        X1573: Label 'Input credit VAT EU purchases %1';
        X1575: Label 'Input credit VAT %1';
        X1577: Label 'Average VAT activity statement KZ 64';
        X1578: Label 'Input credit VAT (§13b UStG)';
        X1579: Label 'Input credit VAT %1 (§13b UStG)';
        X1580: Label 'VAT contra account § 4/3 EStG';
        X1581: Label 'Reversal VAT prev. FY § 4/3 EStG';
        X1582: Label 'VAT on investments §4/3 EStG';
        X1584: Label 'Input credit VAT purch. of veh. in EU w/o VAT ID';
        X1586: Label 'Reduction BerlinFG';
        X1588: Label 'Import VAT paid';
        X1590: Label 'Transitory items';
        X1591: Label 'Client funds';
        X1592: Label 'Settl.acc.f.rec.adv. paym. if post. via debt. acc.';
        X1593: Label 'Total input credit VAT';
        X1594: Label 'Receivables from affiliated companies';
        X1595: Label 'Remaining term up to 1 year';
        X1596: Label 'Remaining term more than 1 year';
        X1598: Label 'Total receivables from affiliated companies';
        X1600: Label 'Trade payables';
        X1601: Label 'Trade payables domestic';
        X1602: Label 'Trade payables other countries';
        X1603: Label 'Intercompany payables';
        X1610: Label 'Payables without current account';
        X1625: Label 'Remaining term up to 1 year';
        X1626: Label 'Remaining term 1-5 years';
        X1628: Label 'Remaining term more than 5 years';
        X1629: Label 'Total liabilities without current account';
        X1630: Label 'Liabilities to associated companies';
        X1631: Label 'Remaining term up to 1 year';
        X1635: Label 'Remaining term 1-5 years';
        X1638: Label 'Remaining term more than 5 years';
        X1639: Label 'Total liabilities to affiliated companies';
        X1640: Label 'Liabilities to associated companies';
        X1641: Label 'Remaining term up to 1 year';
        X1645: Label 'Remaining term 1-5 years';
        X1648: Label 'Remaining term more than 5 years';
        X1649: Label 'Total liabilities to associated companies';
        X1650: Label 'Liabilities to shareholders';
        X1651: Label 'Remaining term up to 1 year';
        X1655: Label 'Remaining term 1-5 years';
        X1657: Label 'Remaining term more than 5 years';
        X1658: Label 'Total liabilities to shareholders';
        X1659: Label 'Total trade payables';
        X1660: Label 'Notes payable';
        X1661: Label 'Remaining term up to 1 year';
        X1680: Label 'Remaining term 1-5 years';
        X1690: Label 'Remaining term more than 5 years';
        X1700: Label 'Other liabilities';
        X1701: Label 'Remaining term up to 1 year';
        X1702: Label 'Remaining term 1-5 years';
        X1703: Label 'Remaining term more than 5 years';
        X1704: Label 'Total other liabilities';
        X1705: Label 'Lendings';
        X1706: Label 'Remaining term up to 1 year';
        X1707: Label 'Remaining term > 1 year';
        X1708: Label 'Total lendings';
        X1709: Label 'Total notes payable/other payables';
        X1710: Label 'Advance payments received';
        X1711: Label 'Taxed advance payments %1 VAT';
        X1717: Label 'Taxed advance payment %1 VAT';
        X1719: Label 'Remaining term up to 1 year';
        X1720: Label 'Remaining term 1-5 years';
        X1721: Label 'Remaining term more than 5 years';
        X1722: Label 'offset openly from inventories';
        X1729: Label 'Credit card statement';
        X1730: Label 'Total advance payments received';
        X1731: Label 'Security deposits received';
        X1732: Label '- Remaining term up to 1 year';
        X1733: Label '- Remaining term 1-5 years';
        X1734: Label '- Remaining term more than 5 years';
        X1735: Label 'Liabilities for taxes / levies';
        X1736: Label '- Remaining term up to 1 year';
        X1737: Label '- Remaining term 1-5 years';
        X1738: Label '- Remaining term more than 5 years';
        X1739: Label 'Liabilities from wages and salaries';
        X1740: Label 'Liabilities from wages and salaries';
        X1741: Label 'Liabilities from payroll and church tax';
        X1742: Label 'Social security liabilities';
        X1743: Label '- Remaining term up to 1 year';
        X1744: Label '- Remaining term 1-5 years';
        X1745: Label '- Remaining term more than 5 years';
        X1746: Label 'Liabilities from withholding tax (KapESt)';
        X1747: Label 'Liabilities from consumption taxes';
        X1748: Label 'Liabilities for the retention of employees';
        X1749: Label 'Liabilities to tax office from building tax disc.';
        X1750: Label 'Liabilities for capital formation';
        X1751: Label '- Remaining term up to 1 year';
        X1752: Label '- Remaining term 1-5 years';
        X1753: Label '- Remaining term more than 5 years';
        X1755: Label 'Settlement account for wages and salaries';
        X1756: Label 'Total security deposits/liabilities';
        X1757: Label 'VAT';
        X1758: Label 'VAT input credit method %1 VAT';
        X1760: Label 'VAT not due';
        X1761: Label 'VAT not due %1';
        X1762: Label 'VAT not due from EU deliveries taxable domestic.';
        X1763: Label 'VAT not due from EU deliv. taxable domestic. %1';
        X1765: Label 'VAT not due %1';
        X1767: Label 'VAT from deliveries taxable in other EU countries';
        X1768: Label 'VAT from others taxable in other EU countries';
        X1771: Label 'VAT %1';
        X1772: Label 'VAT EU purchases';
        X1773: Label 'VAT EU purchases %1';
        X1775: Label 'VAT %1';
        X1777: Label 'VAT from EU deliveries taxable domestically';
        X1778: Label 'VAT from EU deliveries taxable domestically %1';
        X1779: Label 'from EU purchases without VAT input';
        X1780: Label 'VAT prepayments from activity statements';
        X1781: Label 'VAT prepayments from activity statements 1/11';
        X1782: Label 'Back taxes, VAT activity statement KZ 65';
        X1783: Label 'inv. w/ incor. VAT amount or not eligible for VAT';
        X1784: Label 'VAT from EU vehicle purchases';
        X1785: Label 'VAT purs. to § 13b UStG';
        X1786: Label 'VAT purs. to § 13b UStG %1';
        X1788: Label 'Deferred import VAT';
        X1789: Label 'VAT this FY';
        X1790: Label 'VAT previous FY';
        X1791: Label 'VAT prev. years';
        X1792: Label 'Other settlement accounts';
        X1798: Label 'Total VAT';
        X1799: Label 'Private personally liable partners/sole traders';
        X1800: Label 'Personal withdrawals general';
        X1810: Label 'Private taxes';
        X1820: Label 'Extraordinary expenses partially deductible';
        X1830: Label 'Extraordinary expenses fully deductible';
        X1840: Label 'Grants, donations';
        X1850: Label 'Extraordinary expenses';
        X1860: Label 'Expenses for real estate';
        X1870: Label 'Income from real estate';
        X1880: Label 'Assets disposed without consideration';
        X1890: Label 'Private capital contributions';
        X1898: Label 'Total private personally liable partners';
        X1899: Label 'Private limited partners';
        X1900: Label 'Personal withdrawals general';
        X1910: Label 'Private taxes';
        X1920: Label 'Extraordinary expenses partially deductible';
        X1930: Label 'Extraordinary expenses fully deductible';
        X1940: Label 'Grants, donations';
        X1950: Label 'Extraordinary expenses';
        X1960: Label 'Expenses for real estate';
        X1970: Label 'Earnings from real estate';
        X1980: Label 'Assets disposed without consideration';
        X1990: Label 'Private capital contributions';
        X1998: Label 'Total private limited partners';
        X1999: Label 'Extraordinary expenses in the meaning of BiRiLiG';
        X2000: Label 'Extraordinary Expenses';
        X2001: Label 'Extraordinary expenses through profit and loss';
        X2005: Label 'Extraord. expenditure not through profit and loss';
        X2008: Label 'Total extraordinary expenses BiRiLiG';
        X2009: Label 'Non-operational/out-of-period expenses';
        X2010: Label 'Non-operational expenses (not extra-ordinary)';
        X2020: Label 'Out-of-period expenses (not extra-ordinary)';
        X2099: Label 'Total non-operational/out-of-period expenses';
        X2100: Label 'Interest and similar expenses';
        X2107: Label 'Interest expenses §233a AO corporate taxes';
        X2108: Label 'Interest expenses §233a... AO personal taxes';
        X2109: Label 'Interest expenses paid to affiliated companies';
        X2110: Label 'Interest expenses for short-term liabilities';
        X2114: Label 'Non-deductible interest on debt (§4Abs.4aEStG)';
        X2115: Label '100%/50% non-deductible';
        X2116: Label 'to affiliated companies 100%/50% non-deductible';
        X2118: Label 'Interest reclassified as permanent';
        X2119: Label 'for short-term liabilities to affiliated companies';
        X2120: Label 'Interest expenses for long-term liabilities';
        X2126: Label 'Interest for financing non-current assets';
        X2127: Label 'Annuities/Charges § 8 GewStG';
        X2129: Label 'for long-term liabilities to affiliated companies';
        X2130: Label 'Discounting expenses';
        X2139: Label 'Discounting expenses to affiliated companies';
        X2140: Label 'Expenses similar to interest';
        X2149: Label 'Expenses similar to interests to affiliated comp.';
        X2150: Label 'Expenditure for unrealized exchange rate diff.';
        X2160: Label 'Expenditure for realized exchange rate differences';
        X2165: Label 'Expenses for switching to Euro';
        X2166: Label 'Expenses from the measurement of financial funds';
        X2167: Label 'Rounding';
        X2170: Label 'VAT not eligible for input credit';
        X2171: Label 'VAT not eligible for input credit %1';
        X2175: Label 'VAT not eligible for input credit %1';
        X2177: Label 'Total interest & similar expenses';
        X2199: Label 'Tax expenses';
        X2200: Label 'Corporate income tax';
        X2203: Label 'Corporate income tax previous years';
        X2208: Label 'Solidarity surcharge';
        X2209: Label 'Solidarity surcharge previous years';
        X2210: Label 'Capital gains tax 25%';
        X2212: Label 'Capital gains tax 20%';
        X2213: Label 'Solidarity surch. credited to cap. gains tax 20%';
        X2215: Label 'Interest withholding tax';
        X2218: Label 'Solidarity surcharge credited to withholding tax';
        X2223: Label 'Wealth tax for previous years';
        X2280: Label 'Back taxes payments for previous years';
        X2282: Label 'Tax refunds previous years';
        X2284: Label 'Income from the reversal of provisions';
        X2285: Label 'Other back taxes payments prev. years';
        X2287: Label 'Tax refund claims previous years';
        X2289: Label 'Income from the reversal of provisions for taxes';
        X2298: Label 'Total tax expenses';
        X2300: Label 'Other expenses';
        X2307: Label 'Other non-operational expenses/recurring';
        X2309: Label 'Other non-recurring expenses';
        X2310: Label 'Asset disposals (carrying amount after loss)';
        X2311: Label 'Intangible assets disposals (book value loss)';
        X2312: Label 'Financial assets disposals (book value loss)';
        X2313: Label 'Financ. assets disposals (book value loss) 100/50%';
        X2315: Label 'Asset disposals (book value gain)';
        X2318: Label 'Financ. assets disposals (book value loss) 100/50%';
        X2320: Label 'Losses from disposal of non-current assets';
        X2323: Label 'Losses from disposal of non-current assets';
        X2325: Label 'Losses from disposal of current assets';
        X2340: Label 'Posting to special item with provision (free)';
        X2341: Label 'Posting to special item with reserves (Ans.)';
        X2345: Label 'Posting to special item with reserves (Ab.)';
        X2347: Label 'Posting to special item with provision (euro)';
        X2348: Label 'from liabiliies values lower under tax law';
        X2349: Label 'from provisions valued lower under tax law';
        X2350: Label 'Expenses for land holdings';
        X2375: Label 'Property tax';
        X2380: Label 'Grants/donations, not tax-deductible';
        X2381: Label 'Grants/donations science and culture';
        X2382: Label 'Grants/donations charitable purposes';
        X2383: Label 'Grants/donations religious communities';
        X2384: Label 'Grants/donations political parties';
        X2385: Label 'non-deductible 50% of supervisory board compens.';
        X2386: Label 'deductible supervisory board compensation';
        X2387: Label 'Grants/donations §52 Abs.2 Nr.1-3AO';
        X2388: Label 'Grants/donations §52 Abs.2 Nr.4 AO';
        X2389: Label 'Grants/donations to foundations';
        X2400: Label 'Bad debt (usual amount)';
        X2401: Label 'Bad debt %1';
        X2402: Label 'Bad debt tax free EU purchase';
        X2403: Label 'Bad debt EU purchases %1';
        X2404: Label 'from EU deliveries taxable domestically %1';
        X2405: Label 'Bad debt %1';
        X2430: Label 'Bad debt unusually high';
        X2450: Label 'Posting in bad debt allow. for receiv. (lump sum)';
        X2451: Label 'Posting in bad debt allow. for receiv. (individ.)';
        X2460: Label 'Total bad debt';
        X2489: Label 'Expenses from absorption of losses';
        X2490: Label 'Expenses from absorption of losses';
        X2491: Label 'Profits disbursed to profit pool';
        X2492: Label 'Profits transferred';
        X2493: Label 'Profits transferred';
        X2494: Label 'Additions to capital reserves';
        X2495: Label 'Additions to compulsory reserves';
        X2496: Label 'Additions to statutory reserve';
        X2497: Label 'Total expenses from absorption of losses';
        X2498: Label 'Total other expenses';
        X2499: Label 'Extraordinary income in the meaning of BiRiLiG';
        X2500: Label 'Extraordinary income';
        X2501: Label 'Extraordinary income';
        X2502: Label 'Extraordinary income through P/L';
        X2505: Label 'Extraordinary income not through P/L';
        X2508: Label 'Total extraordinary income';
        X2509: Label 'Non-operational/out-of-period income';
        X2510: Label 'Non-operational income (not extra-ordinary)';
        X2520: Label 'Period external revenues (not extraordinary)';
        X2521: Label 'Total non-operational/out-of-period income';
        X2599: Label 'Interest income';
        X2600: Label 'Income from participating interests';
        X2601: Label 'Ongoing income stock corporation 100% / 50%';
        X2602: Label 'Profit share partners §9GewStG';
        X2603: Label 'Inc. from particip. interests in affiliated comp.';
        X2604: Label 'Total income from participating interests';
        X2605: Label 'Income from other securities';
        X2620: Label 'Income from other securities';
        X2621: Label 'Current revenue share financial asset 100% / 50%';
        X2622: Label 'Current revenue share associated 100% / 50%';
        X2625: Label 'Income from securities/financial assets';
        X2626: Label 'Total income from other securities';
        X2649: Label 'Other interest and similar income';
        X2650: Label 'Other interest and similar income';
        X2655: Label 'Curr. revenues shares circulating assets 100%/50%';
        X2656: Label 'Current revenue share associated 100% / 50%';
        X2657: Label 'Interest income §233a AO business tax';
        X2658: Label 'Interest income §233a AO corporate income tax';
        X2659: Label 'other interest and similar income from aff. comp.';
        X2660: Label 'Income from unrealized exchange rate differences';
        X2662: Label 'Income from realized exchange rate differences';
        X2665: Label 'Income from switch to Euro';
        X2666: Label 'Income from measurement of financial funds';
        X2670: Label 'Discounting income';
        X2679: Label 'Discounting income affiliated companies';
        X2680: Label 'Income similar to interest';
        X2685: Label 'Other interest and similar income';
        X2686: Label 'Total other interest and similar income';
        X2695: Label 'Total interest income';
        X2699: Label 'Total extraordinary income';
        X2700: Label 'Other income';
        X2705: Label 'Other operational and recurring income';
        X2707: Label 'Other non-operational and recurring income';
        X2709: Label 'Other non-recurring income';
        X2710: Label 'Inc. from appreciation of prop., plant and equipm.';
        X2711: Label 'Income from appreciation of intangible assets';
        X2712: Label 'Income from appreciation of financial assets';
        X2713: Label 'Inc. from appreciation of financ. assets 100%/50%';
        X2714: Label 'Income from appreciation of other assets 100%/50%';
        X2715: Label 'Income from appreciation of current assets';
        X2716: Label 'Income from appreciation of curr. assets 100%/50%';
        X2720: Label 'Income from the disposal of non-current assets';
        X2723: Label 'Inc. from the disp. of non-curr. assets 100%/50%';
        X2725: Label 'Income from the disposal of current assets';
        X2730: Label 'Inc. from the reduct. of lump-sum bad debt allow.';
        X2731: Label 'Inc. from reduct. of item-specific bad debt allow.';
        X2732: Label 'Income from receivables written off';
        X2734: Label 'Income tax low-value receivables';
        X2735: Label 'Income from the reversal of provisions ';
        X2736: Label 'Income from reduction of liabilities';
        X2737: Label 'Inc. from rev. of tax provisions (switch to Euro)';
        X2738: Label 'Income from reversal of tax provisions §52 (16)';
        X2739: Label 'Inc. from rev. of tax provisions (capital form.)';
        X2740: Label 'Reversal of special item w/ provisions (free)';
        X2741: Label 'Rev. of special item w/ provisions (amortization)';
        X2742: Label 'Insurance benefits';
        X2743: Label 'Investment grant (required)';
        X2744: Label 'Investment subsidies (free)';
        X2745: Label 'Income from capital reduction';
        X2750: Label 'Income from land holdings';
        X2790: Label 'Income from absorption of losses';
        X2792: Label 'Profits from profit pool';
        X2794: Label 'Profits from (partial) profit transfer agreements';
        X2795: Label 'Capital reserve withdrawals';
        X2796: Label 'Withdrawals from compulsory provisions';
        X2797: Label 'Withdrawals from statutory provisions';
        X2798: Label 'Withdr. from the prov. for cap. treasury shares';
        X2799: Label 'Withdrawals from other retained profits';
        X2800: Label 'Total other income';
        X2860: Label 'Profits carried forward after appropriation';
        X2862: Label 'Gain carried forward 40% reserved';
        X2864: Label 'Profits carried forward 0% reserved (EK04)';
        X2866: Label 'Profits carried forward 0% reserved (EK02)';
        X2868: Label 'Losses carried forward after appropriation';
        X2869: Label 'Carryforwards to new FY (P&L)';
        X2870: Label 'Advance distribution';
        X2879: Label 'Total profits/losses carried forward';
        X2889: Label 'Imputed costs offset';
        X2890: Label 'Imputed shareholder salary offset';
        X2891: Label 'Imputed rents and leases offset';
        X2892: Label 'Imputed interest offset';
        X2893: Label 'Imputed amortization offset';
        X2894: Label 'Imputed risks offset';
        X2895: Label 'Imputed wages for employees working free of charge';
        X2990: Label 'Income/expenses from conversion differences';
        X2996: Label 'Total imputed costs offset';
        X2999: Label 'Cost of materials';
        X3000: Label 'Raw, auxiliary, operating materials';
        X3090: Label 'Energy media (manufacturing)';
        X3099: Label 'Total cost of materials';
        X3100: Label 'Externally procured services';
        X3110: Label 'Constr. service domestic comp. VAT %1 both ends';
        X3115: Label 'Service foreign company VAT %1 both ends';
        X3120: Label 'Constr. service domestic comp. VAT %1 both ends';
        X3125: Label 'Service foreign company VAT %1 both ends';
        X3130: Label 'Cons.serv.dom.comp.VAT-fr. purch.,%1 VAT on sale';
        X3135: Label 'Serv. foreign comp. VAT-fr.purch.,%1 VAT on sale';
        X3140: Label 'Constr.serv.dom.comp.VAT-fr.purch.,%1VAT on sale';
        X3145: Label 'Serv. foreign comp. VAT-fr.purch.,%1 VAT on sale';
        X3150: Label 'Total externally procured services';
        X3200: Label 'Goods receipt';
        X3300: Label 'Goods receipt %1 VAT';
        X3400: Label 'Goods receipt %1 VAT';
        X3420: Label 'EU purchases %1 VAT both ends';
        X3425: Label 'EU purchases %1 VAT both ends';
        X3430: Label 'EU purchases VAT-free purchase / %1 VAT on sale';
        X3435: Label 'EU purchases VAT-free purchase / %1 VAT on sale';
        X3550: Label 'Tax free EU purchases';
        X3559: Label 'Tax free imports';
        X3598: Label 'Total goods receipt';
        X3600: Label 'VAT not eligible for input credit';
        X3610: Label 'VAT not eligible for input credit VAT %1';
        X3650: Label 'VAT not eligible for input credit VAT %1';
        X3698: Label 'Total VAT not eligible for input credit';
        X3700: Label 'Discounts';
        X3710: Label 'Discounts %1 VAT';
        X3720: Label 'Discounts %1 VAT';
        X3724: Label 'Discounts EU purchases %1 VAT both ends';
        X3725: Label 'Discounts EU purchases %1 VAT both ends';
        X3726: Label 'Discount received';
        X3728: Label 'Total discounts';
        X3729: Label 'Discounts/bonuses/price concessions';
        X3730: Label 'Discounts received';
        X3731: Label 'Discounts received %1 VAT';
        X3732: Label 'Discounts received %1 VAT';
        X3733: Label 'Payment tolerance received';
        X3734: Label 'Payment tolerance received';
        X3736: Label 'Discounts received';
        X3737: Label 'Total discounts received';
        X3740: Label 'Bonuses received';
        X3750: Label 'Bonuses received %1 VAT';
        X3760: Label 'Bonuses received %1 VAT';
        X3765: Label 'Total bonuses received';
        X3770: Label 'Payment discounts received';
        X3780: Label 'Payment discounts received %1 VAT';
        X3790: Label 'Payment discounts received %1 VAT';
        X3795: Label 'Total bonuses received';
        X3796: Label 'Total payment discounts/bonuses/price concessions';
        X3799: Label 'Additional procurement costs';
        X3800: Label 'Additional procurement costs';
        X3830: Label 'Empty returnable containers';
        X3850: Label 'Customs and import levies';
        X3960: Label 'Inventory change raw, aux., operating materials';
        X3965: Label 'Total additional procurement costs';
        X3969: Label 'Inventories';
        X3970: Label 'Inventories raw, auxiliary, operating materials';
        X3975: Label 'Work in progress costs (project)';
        X3976: Label 'Work in progress sales (project)';
        X3980: Label 'Inventories';
        X3981: Label 'Resale';
        X3982: Label 'Finished goods';
        X3983: Label 'Raw materials';
        X3984: Label 'Resale (interim)';
        X3985: Label 'Finished goods (interim)';
        X3986: Label 'Raw materials (interim)';
        X3987: Label 'Total inventories';
        X3988: Label 'Material costs';
        X3989: Label 'Applied material costs';
        X3990: Label 'Applied material costs (contra acct. 4000-99)';
        X3998: Label 'Total applied material costs';
        X3999: Label 'Materials consumption';
        X4000: Label 'Materials consumption';
        X4090: Label 'Ancillary costs of sales';
        X4091: Label 'Direct cost applied';
        X4092: Label 'Overhead cost applied';
        X4093: Label 'Purchase variance';
        X4097: Label 'Total materials consumption';
        X4098: Label 'Total material costs';
        X4099: Label 'Personnel expenses';
        X4100: Label 'Wages and salaries';
        X4110: Label 'Wages';
        X4120: Label 'Salaries';
        X4124: Label 'CEO salaries GmbH';
        X4125: Label 'Spouse wage or salary';
        X4126: Label 'Management bonus';
        X4127: Label 'CEO salaries';
        X4130: Label 'Statutory social security expenses';
        X4137: Label 'Statutory social security expenses partner';
        X4138: Label 'Liability insurance fees for the employer';
        X4139: Label 'Compensatory levy severe disability';
        X4140: Label 'Voluntary social security contributions tax free';
        X4145: Label 'Voluntary social security contributions taxable';
        X4149: Label 'Lumpsum income tax other income';
        X4150: Label 'Sick pay allowances';
        X4160: Label 'Pension funds';
        X4165: Label 'Pension scheme expenses';
        X4169: Label 'Support expenses';
        X4170: Label 'Capital-forming payments';
        X4175: Label 'Reimbursement travel expenses home/work';
        X4180: Label 'Tips';
        X4190: Label 'Salaries paid to casuals';
        X4197: Label 'Income tax casuals';
        X4198: Label 'Total personnel expenses';
        X4199: Label 'Other operational expenses and amortization';
        X4204: Label 'Other operational expenses';
        X4205: Label 'Occupancy expenses';
        X4210: Label 'Rental expenses';
        X4218: Label 'Rental income to be incl. In profits §8GewStG';
        X4220: Label 'Leasing expenses';
        X4228: Label 'Leasing income to be incl. in profits §8GewStG';
        X4230: Label 'Heating';
        X4240: Label 'Gas, electricity, water';
        X4250: Label 'Cleaning';
        X4260: Label 'Maintenance operational premises';
        X4270: Label 'Charges for operationally used real property';
        X4280: Label 'Miscellaneous occupancy costs';
        X4300: Label 'VAT not eligible for input credit';
        X4301: Label 'VAT not eligible for input credit %1';
        X4305: Label 'VAT not eligible for input credit %1';
        X4320: Label 'Trade tax';
        X4340: Label 'Other business taxes';
        X4350: Label 'Consumption tax';
        X4360: Label 'Insurances';
        X4380: Label 'Fees';
        X4390: Label 'Other charges';
        X4500: Label 'Vehicle expenses';
        X4510: Label 'Vehicle taxes';
        X4520: Label 'Vehicle insurances';
        X4530: Label 'Ongoing vehicle operational expenses';
        X4540: Label 'Vehicle repairs';
        X4550: Label 'Rental expenses for garages';
        X4570: Label 'Third-party vehicles';
        X4580: Label 'Other vehicle expenses';
        X4600: Label 'Travel and other related expenses';
        X4610: Label 'Advertising expenses';
        X4630: Label 'Gifts up to 75 EUR';
        X4635: Label 'Gifts of more than 75 EUR';
        X4638: Label 'Gifts exclusively used in business operations';
        X4640: Label 'Representation expenses';
        X4650: Label 'Entertainment expenses';
        X4653: Label 'Courtesies';
        X4654: Label 'Non-deductible entertainment expenses';
        X4655: Label 'Non-deductible operating expenses';
        X4660: Label 'Travel expenses employees';
        X4670: Label 'Travel expenses partner/owner';
        X4700: Label 'Delivery costs';
        X4710: Label 'Packaging materials';
        X4730: Label 'Outbound cargo';
        X4750: Label 'Transport insurances';
        X4760: Label 'Sales commissions';
        X4780: Label 'Subcontracted performances';
        X4790: Label 'Expenditure for warranty claims';
        X4800: Label 'Repair/maintenance plant/machines';
        X4805: Label 'Repair/maintenance other plants/BGA';
        X4809: Label 'Other repair/maintenance';
        X4810: Label 'Leasing';
        X4811: Label 'Trade tax leasing (rental) to be considered';
        X4812: Label 'Total other operational expenses';
        X4813: Label 'Amortization';
        X4814: Label 'Amortization on intangible assets';
        X4815: Label 'Hire purchase';
        X4820: Label 'Amortization of exp. for start-up/exp. of bus. op.';
        X4821: Label 'Amortization of expenses for switch to Euro';
        X4822: Label 'Amortization on intangible assets';
        X4824: Label 'Amortization on goodwill/business value';
        X4826: Label 'Unscheduled amortization on intangible assets';
        X4830: Label 'Amortization on property, plant and equipment';
        X4840: Label 'Unscheduled amort. on prop., plant and equipm.';
        X4850: Label 'Depr. of tangib. fixed assets special tax. benefit';
        X4855: Label 'Immediate write-off low-value assets';
        X4860: Label 'Amortization on capitalized low-value assets';
        X4865: Label 'Unsch. amortiz. on capitalized low-value assets';
        X4868: Label 'Total amortization on intangible assets';
        X4869: Label 'Amortization on financial assets';
        X4870: Label 'Amortization on financial assets';
        X4871: Label 'Amortiz. on financ. assets 100%/50% non-deductible';
        X4872: Label 'Amortization on loss share partners';
        X4873: Label 'Amortiz. on financ. assets 100%/50% non-deductible';
        X4874: Label 'Amortiz. on financial assets special tax. benefit';
        X4875: Label 'Amortization on current securities';
        X4876: Label 'Amortization on securities 100%/50% non-deductible';
        X4877: Label 'Anticipated future fluctuation of bonds RV';
        X4878: Label 'Total amortization on financial assets';
        X4879: Label 'Amortization on current assets';
        X4880: Label 'Amortiz. of curr. assets excl. sec. (regular am.)';
        X4881: Label 'Amortiz. on RV deferred taxes cond. (unusual am.)';
        X4882: Label 'Total amortization on current assets';
        X4883: Label 'Total amortization expenses';
        X4884: Label 'Other operating expenses';
        X4885: Label 'Anticipated future fluctuation RV w/o privilege';
        X4886: Label 'Amort. on curr .ass.excl. Inv. and sec. (reg. am.)';
        X4887: Label 'Amort. on RV deferred taxes cond. (usual amount)';
        X4890: Label 'Anticipated future fluctuation RV (unusual amount)';
        X4900: Label 'Other operating expenses';
        X4905: Label 'Other operational/recurring expenses';
        X4910: Label 'Postage';
        X4920: Label 'Telephone';
        X4925: Label 'Telefax, telex';
        X4930: Label 'Office supplies';
        X4940: Label 'Magazines/books';
        X4945: Label 'Personnel training expenses';
        X4946: Label 'Voluntary social benefits';
        X4948: Label 'Payments to freelancing partners';
        X4950: Label 'Legal and consultancy fees';
        X4955: Label 'Accounting fees';
        X4957: Label 'Expenses for financial statements and auditors';
        X4960: Label 'Rental expenses for furnishings/fit-outs';
        X4965: Label 'Leasing';
        X4966: Label 'Bus. tax leasing(rental) to be considered §8GewStG';
        X4968: Label 'Bus. tax rentals to be consid. for gain §8GewStG';
        X4969: Label 'Expenditure for disposal of excavation/waste';
        X4970: Label 'Ancillary costs related to financial transactions';
        X4975: Label 'Expenses related to shares in stock corp. 100%/50%';
        X4976: Label 'Exp.rel.to disp. of shares in stock corp. 100%/50%';
        X4980: Label 'Operational expenses';
        X4985: Label 'Tools and small devices';
        X4986: Label 'Total other related expenditure';
        X4988: Label 'Total other operational expenses/amortization';
        X4989: Label 'Imputed costs offset';
        X4990: Label 'Imputed salary of the owner';
        X4991: Label 'Imputed rental and leasing expenses';
        X4992: Label 'Imputed interest';
        X4993: Label 'Imputed amortization';
        X4994: Label 'Total imputed costs';
        X4995: Label 'Costs of applying the cost of sales method';
        X4996: Label 'Manufacturing costs';
        X4997: Label 'Administration/sales costs';
        X4998: Label 'Contra account 4996-4997';
        X4999: Label 'Total cost of applying the cost of sales method';
        X5000: Label 'Costs';
        X5001: Label 'Project costs';
        X5002: Label 'Project costs - projects';
        X5003: Label 'Project costs - article';
        X5004: Label 'Project costs - resources';
        X5005: Label 'Project costs - finance';
        X5010: Label 'Total project costs';
        X5089: Label 'Variance';
        X5090: Label 'Materials variance';
        X5091: Label 'Capacity variance';
        X5092: Label 'Subcontracted works variance';
        X5093: Label 'Capital overheads variance';
        X5094: Label 'Manufacturing overheads variance';
        X5100: Label 'Total variance';
        X5999: Label 'Total costs';
        X7000: Label 'Work in progress (inventory)';
        X7050: Label 'Work in progress';
        X7080: Label 'Work in progress';
        X7090: Label 'Construction orders in progress';
        X7095: Label 'Orders in progress';
        X7099: Label 'Total work in process';
        X7100: Label 'Finished goods/products (inventory)';
        X7110: Label 'Finished goods';
        X7120: Label 'Purchase, trade - EU';
        X7130: Label 'Purchase, trade - import';
        X7140: Label 'Goods';
        X7149: Label 'Total finished goods';
        X8000: Label 'Revenues';
        X8099: Label 'Revenues I';
        X8100: Label 'Tax-free sales §.4 Nr. 8ff UStG';
        X8110: Label 'Other tax-free domestic revenues';
        X8120: Label 'Tax free revenues §4 Nr.1a,c,2-7UStG';
        X8125: Label 'Tax free deliveries §4 Nr. 1b UStG';
        X8128: Label 'Tax free deliveries, contract processing';
        X8130: Label 'Deliv. of the first recip. in 3-party EU transac.';
        X8140: Label 'Tax-free offshore revenues etc.';
        X8150: Label 'Other foreign tax-free revenues';
        X8196: Label 'Income from slot machines %1 VAT';
        X8199: Label 'Total revenues I';
        X8200: Label 'Revenues II';
        X8300: Label 'Revenues %1 VAT';
        X8310: Label 'Revenues from EU deliveries taxable domestic. %1';
        X8315: Label 'Revenues from EU deliveries taxable domestic. %1';
        X8320: Label 'Revenues from deliv. taxable in another EU country';
        X8338: Label 'Rev. from deliv. tax. in 3rd count., not tax. dom.';
        X8339: Label 'Rev. from services taxable in another EU country';
        X8400: Label 'Revenues %1 VAT';
        X8405: Label 'Total revenues II';
        X8450: Label 'Project revenues';
        X8451: Label 'Project revenues';
        X8452: Label 'Revenues, other project costs';
        X8460: Label 'Total project revenues';
        X8500: Label 'Commission revenues';
        X8505: Label 'Commission revenues tax-free';
        X8506: Label 'Commission revenues %1 VAT';
        X8508: Label 'Commission revenues %1 VAT';
        X8509: Label 'Total commission revenues';
        X8511: Label 'Miscellaneous revenues';
        X8515: Label 'Fuel';
        X8520: Label 'Revenues from waste recycling';
        X8530: Label 'Repairs and maintenance';
        X8540: Label 'Revenues empty returnable containers';
        X8549: Label 'Total miscellaneous revenues';
        X8550: Label 'Total revenues';
        X8589: Label 'Other operational income';
        X8590: Label 'Benefits in kind offset';
        X8591: Label 'Benefits in kind %1 VAT (goods)';
        X8595: Label 'Benefits in kind %1VAT (goods)';
        X8600: Label 'Other revenues operational/regular';
        X8610: Label 'Applied other benefits in kind';
        X8611: Label 'Applied other benefits in kind %1 sales tax';
        X8620: Label 'Bad debt expenses';
        X8625: Label 'Other revenues operational tax free';
        X8630: Label 'Other revenues operational/recurring %1';
        X8640: Label 'Other revenues operational/recurring %1';
        X8645: Label 'Total other operational income';
        X8649: Label 'Interest and similar income';
        X8650: Label 'Revenues interest/discount charges';
        X8660: Label 'Rev. interests/disc. charges affiliated companies';
        X8699: Label 'Total other interest and similar income';
        X8700: Label 'Revenue reductions';
        X8705: Label 'Revenue reductions tax-free';
        X8710: Label 'Revenue reductions %1VAT';
        X8720: Label 'Revenue reductions %1 VAT';
        X8725: Label 'Rev. from EU deliveries taxable domestically %1';
        X8726: Label 'Rev. from EU deliveries taxable domestically %1';
        X8730: Label 'Payment discounts granted';
        X8731: Label 'Payment discounts granted %1VAT';
        X8732: Label 'Payment discounts granted %1 VAT';
        X8733: Label 'Payment discounts granted';
        X8734: Label 'Payment tolerance granted';
        X8735: Label 'Payment tolerance granted - correction';
        X8737: Label 'Total payment discounts granted';
        X8740: Label 'Bonuses granted';
        X8750: Label 'Bonuses granted %1';
        X8760: Label 'Bonuses granted %1 VAT';
        X8765: Label 'Total bonuses granted';
        X8770: Label 'Payment discounts granted';
        X8780: Label 'Payment discounts granted %1 VAT';
        X8790: Label 'Payment discounts granted %1 VAT';
        X8791: Label 'Payment discounts granted';
        X8795: Label 'Total payment discounts granted';
        X8798: Label 'Total revenue reductions';
        X8800: Label 'Revenues from asset sales';
        X8801: Label 'Revenues from asset sales %1 (book value loss)';
        X8807: Label 'Revenues from asset sales tax-free (§4Nr.1aUStG)';
        X8808: Label 'Revenues from asset sales tax-free (§4Nr.1bUStG)';
        X8809: Label 'Revenues from asset sales %1 (book value loss)';
        X8817: Label 'Revenues from intangible assets (book value loss)';
        X8818: Label 'Revenues from asset sales (book value loss)';
        X8819: Label 'Rev. from asset sales (book value loss) 100/50%';
        X8820: Label 'Revenues from asset sales %1 (book value gain)';
        X8827: Label 'Revenues from asset sales tax-free (§4Nr.1aUStG)';
        X8828: Label 'Revenues from asset sales tax-free (§4Nr.1bUStG)';
        X8829: Label 'Revenues from asset sales (book value gain)';
        X8837: Label 'Rev. from sale of intang. asset (book value gain)';
        X8838: Label 'Revenues from asset sales (book value loss)';
        X8839: Label 'Rev. from asset sales (book value loss) 100/50%';
        X8840: Label 'Total revenues from asset sales';
        X8900: Label 'Assets disposed without consideration';
        X8905: Label 'Withdrawals VAT/free';
        X8910: Label 'Withdrawals %1 §1Abs1UStG';
        X8915: Label 'Withdrawals %1 §1 Abs.1 UStG';
        X8916: Label 'Shareholder withdrawals';
        X8919: Label 'Total disposals without consideration';
        X8920: Label 'Utilization outside of the company';
        X8921: Label 'Utilization of property %1 sales tax';
        X8930: Label 'Utilization of property %1 sales tax';
        X8935: Label 'Gratuities VAT-free';
        X8939: Label 'Total allocation outside';
        X8940: Label 'Gratuities (goods)';
        X8941: Label 'Gratuities %1 VAT';
        X8945: Label 'Gratuities (goods) 7 %';
        X8949: Label 'Gratuities (goods) VAT-free';
        X8950: Label 'Tax-exempt revenues';
        X8955: Label 'VAT refunds';
        X8956: Label 'Total gratuities';
        X8959: Label 'Changes in inventories';
        X8960: Label 'Changes in inventories unfinished goods';
        X8970: Label 'Changes in inventories incomplete services';
        X8975: Label 'Changes in inventories constr. orders in progress';
        X8977: Label 'Changes in inventories orders in progress';
        X8980: Label 'Changes in inventories finished goods';
        X8988: Label 'Total changes in inventories';
        X8989: Label 'Other activated services';
        X8990: Label 'Other activated services';
        X8995: Label 'Total other activated services';
        X9000: Label 'Carry-forward accounts';
        X9001: Label 'Carry-forward general ledger accounts';
        X9008: Label 'Carry-forward debtor accounts';
        X9009: Label 'Carry-forward creditor accounts';
        X9060: Label 'Open items from 1990';
        X9069: Label 'Open items from 1999';
        X9070: Label 'Open items from 2000';
        X9071: Label 'Open items from 2001';
        X9072: Label 'Open items from 2002';
        X9073: Label 'Open items from 2003';
        X9074: Label 'Open items from 2004';
        X9075: Label 'Open items from 2005';
        X9076: Label 'Open items from 2006';
        X9077: Label 'Open items from 2007';
        X9078: Label 'Open items from 2008';
        X9085: Label 'Open items from 1985';
        X9086: Label 'Open items from 1986';
        X9087: Label 'Open items from 1987';
        X9088: Label 'Open items from 1988';
        X9089: Label 'Open items from 1989';
        X9090: Label 'Total carry-forward account';
        X9091: Label 'Open items from 1991';
        X9092: Label 'Open items from 1992';
        X9093: Label 'Open items from 1993';
        X9094: Label 'Open items from 1994';
        X9095: Label 'Open items from 1995';
        X9096: Label 'Open items from 1996';
        X9097: Label 'Open items from 1997';
        X9098: Label 'Open items from 1998';
        X9099: Label 'Total carry-forward account';
        X9100: Label 'Statistical accounts for financial analysis';
        X9101: Label 'Sales days';
        X9102: Label 'Number of cash customers';
        X9103: Label 'Number of employees';
        X9104: Label 'Unpaid persons';
        X9105: Label 'Sales personnel';
        X9106: Label 'Business space in square meters';
        X9107: Label 'Salesfloor in square meters';
        X9108: Label 'Change rate positive';
        X9109: Label 'Change rate negative';
        X9110: Label 'Planned post receipt';
        X9116: Label 'Number of Invoices';
        X9117: Label 'Number of credit customers monthly';
        X9118: Label 'Number of credit customers accrued';
        X9120: Label 'Expansion investments';
        X9190: Label 'Contra account for 9101-9120';
        X9199: Label 'Statistic accounts balance sheet key figures';
        X9200: Label 'Number of employees';
        X9209: Label 'Contra account for 9200';
        X9210: Label 'Productive wages';
        X9219: Label 'Contra account for 9219';
        X9220: Label 'Statistical accounts capital currency';
        X9221: Label 'Subscribed capital in DM';
        X9222: Label 'Subscribed capital in Euro';
        X9229: Label 'Contra account for 9221 - 9222';
        X9230: Label 'Deferred expenses';
        X9231: Label 'Building cost subsidies';
        X9232: Label 'Investment subsidies (free)';
        X9234: Label 'Investment grants';
        X9239: Label 'Contra account for accounts 9231 - 9238';
        X9240: Label 'Investment liabilities in performance liabilities';
        X9241: Label 'Inves. liab. from the purch. of PPE in perf. liab.';
        X9242: Label 'Inv.liab. from purch. of intang.ass. in perf.liab.';
        X9243: Label 'Inv.liab. from purch. of fin. assets in perf.liab.';
        X9244: Label 'Contra account for accounts 9240 - 9243';
        X9245: Label 'Receiv.fr. sale of prop.,plant&equipm. in oth.ass.';
        X9246: Label 'Receiv. from sale of intang. ass. in other ass.';
        X9247: Label 'Receiv. from sale of financ. assets in oth. assets';
        X9249: Label 'Contra account for accounts 9245 - 9247';
        X9250: Label 'Shareholder loans substituting equity';
        X9251: Label 'Shareholder loans substituting equity';
        X9255: Label 'Unsec. shareholder loan w/ residual term > 5 years';
        X9259: Label 'Contra account for 9251 and 9255';
        X9260: Label 'Breakdown of provisions';
        X9261: Label 'Short-term provisions';
        X9262: Label 'Mid-term provisions';
        X9264: Label 'Long-term allowances for pensions';
        X9268: Label 'Contra account for accounts 9261 - 9267';
        X9269: Label 'Stat. acc. for discl. of liab. in balance sheet';
        X9270: Label 'Contra account for 9271-9278 (debit)';
        X9271: Label 'Liab.fr. iss./assign. of bills of exch.affil.comp.';
        X9272: Label 'Liab. from the iss./assignment of bills of exch.';
        X9273: Label 'Liab. from assumption/assign. of bills of exch.';
        X9274: Label 'Liab.fr.assump./assign. of bills of exch.aff.comp.';
        X9275: Label 'Liabilities from warranty contracts';
        X9276: Label 'Liab. from warranty contracts affiliated comp.';
        X9277: Label 'Liab.fr.provis. of collateral for 3rd-party liab.';
        X9278: Label 'Liab.fr.prov.of col. for 3rd-party liab.,aff.comp.';
        X9279: Label 'Statistical accounts other liabilities';
        X9280: Label 'Contra account for 9281 - 9284';
        X9281: Label 'Liabilities from rental and leasing';
        X9282: Label 'Liab. from rental and leasing affiliated companies';
        X9283: Label 'Other liabilities purs. to § 285 Nr.3 HGB';
        X9284: Label 'Other liab. purs. to § 285 Nr.3 HGB associated';
        X9290: Label 'Statistical accounts tax-free disbursements';
        X9291: Label 'Contra account for 9290';
        X9292: Label 'Statistics accounts client funds';
        X9293: Label 'Contra account for 9292';
        X9410: Label 'Due deposits §26DMBilG (not inserted)';
        X9411: Label 'Due deposits §26DMBilG (inserted)';
        X9413: Label 'Exp. for start-up and exp. of business operations';
        X9415: Label 'Free advanced intangible assets';
        X9416: Label 'Usage rights §9 Abs. 3 DMBilG';
        X9420: Label 'Acc.receiv. associated comp. application §25DMBilG';
        X9421: Label 'Remaining term up to 1 year';
        X9422: Label 'Remaining term more than 1 year';
        X9426: Label 'Inserted put-away §26 Abs.3DMBilG';
        X9427: Label 'Compensation claims §24 DMBilG';
        X9428: Label 'Remaining term up to 1 year';
        X9429: Label 'Remaining term more than 1 year';
        X9430: Label 'Receivables VermG §7 Abs.6 DMBilG';
        X9431: Label 'Remaining term up to 1 year';
        X9432: Label 'Remaining term more than 1 year';
        X9433: Label 'Pecuniary advantage §31 Abs. DMBilG';
        X9434: Label 'Capital development account';
        X9435: Label 'Capital development §28 Abs.1 DMBilG';
        X9436: Label 'Capital development §26 Abs.4 DMBilG';
        X9438: Label 'Special benefit allowances § 17 DMBilG';
        X9440: Label 'Share cancellation account';
        X9445: Label 'Preliminary retained profits §31 DMBilG';
        X9446: Label 'Special reserves §7 Abs.4 DMBilG';
        X9447: Label 'Special reserves §17 Abs.4 DMBilG';
        X9448: Label 'Special reserves §24 Abs.5 DMBilG';
        X9449: Label 'Special reserves §27 Abs.2 DMBilG';
        X9450: Label 'Provisions for environmental authorit. §17 DMBilG';
        X9451: Label 'Message capital §16Abs.3 DMBilG';
        X9452: Label 'Impairment or impairment reversal § 36 DMBilG';
        X9453: Label 'Increase of asset items';
        X9454: Label 'Decrease of asset items';
        X9455: Label 'Increase of liability items';
        X9456: Label 'Decrease of liability items';
        X9457: Label 'Liabilities to affiliated companies §24 DMBilG';
        X9458: Label 'Remaining term up to 1 year';
        X9459: Label 'Remaining term 1-5 years';
        X9460: Label 'Remaining term more than 5 years';
        X9462: Label 'Liabilities to affiliated companies §26 DMBilG';
        X9463: Label 'Remaining term up to 1 year';
        X9464: Label 'Remaining term 1-5 years';
        X9465: Label 'Remaining term more than 5 years';
        X9467: Label 'Compensation liabilities §25 DMBilG';
        X9468: Label 'Remaining term up to 1 year';
        X9469: Label 'Remaining term 1-5 years';
        X9470: Label 'Remaining term more than 5 years';
        X9472: Label 'Liabilities VermG §7 DMBilG';
        X9473: Label 'Remaining term up to 1 year';
        X9474: Label 'Remaining term 1-5 years';
        X9475: Label 'Remaining term more than 5 years';
        X9476: Label 'Payables refunds §17 DMBilG';
        X9477: Label 'Remaining term up to 1 year';
        X9478: Label 'Remaining term 1-5 years';
        X9479: Label 'Remaining term more than 5 years';
        X9480: Label 'Resolution capital development §28 DMBilG';
        X9481: Label 'Drawing retained earnings §31DMBilG';
        X9482: Label 'Drawing special reserves settlement loss';
        X9486: Label 'Compensation claims write-off';
        X9487: Label 'Income from reversal of provisions';
        X9499: Label 'Statistical accounts capital account development';
        X9500: Label 'Share of accounts 0900-09';
        X9510: Label 'Share of accounts 0910-19';
        X9520: Label 'Share of accounts 0920-29';
        X9530: Label 'Share of accounts 0830-39';
        X9540: Label 'Share of accounts 0810-19';
        X9570: Label 'Share of accounts 0870-79';
        X9580: Label 'Share of accounts 0810-89';
        X9590: Label 'Share of accounts 0890-99';
        X9600: Label 'Shareholder name';
        X9610: Label 'Wage or Salary';
        X9620: Label 'Management bonus';
        X9630: Label 'Loan interest';
        X9640: Label 'Transfer of the right to use';
        X9650: Label 'Other remuneration';
        BalanceSheetTok: Label 'Balance Sheet', MaxLength = 100;
        AssetsTok: Label 'Assets', MaxLength = 100;
        DevelopmentExpenditureTok: Label 'Development Expenditure', MaxLength = 100;
        TenancySiteLeaseholdandsimilarrightsTok: Label 'Tenancy, Site Leasehold and similar rights', MaxLength = 100;
        GoodwillTok: Label 'Goodwill', MaxLength = 100;
        AdvancedPaymentsforIntangibleFixedAssetsTok: Label 'Advanced Payments for Intangible Fixed Assets', MaxLength = 100;
        BuildingTok: Label 'Building', MaxLength = 100;
        CostofImprovementstoLeasedPropertyTok: Label 'Cost of Improvements to Leased Property', MaxLength = 100;
        LandTok: Label 'Land ', MaxLength = 100;
        EquipmentsandToolsTok: Label 'Equipments and Tools', MaxLength = 100;
        ComputersTok: Label 'Computers', MaxLength = 100;
        CarsandotherTransportEquipmentsTok: Label 'Cars and other Transport Equipments', MaxLength = 100;
        LeasedAssetsTok: Label 'Leased Assets', MaxLength = 100;
        AccumulatedDepreciationTok: Label 'Accumulated Depreciation', MaxLength = 100;
        Long_termReceivablesTok: Label 'Long-term Receivables ', MaxLength = 100;
        ParticipationinGroupCompaniesTok: Label 'Participation in Group Companies', MaxLength = 100;
        LoanstoPartnersorrelatedPartiesTok: Label 'Loans to Partners or related Parties', MaxLength = 100;
        DeferredTaxAssetsTok: Label 'Deferred Tax Assets', MaxLength = 100;
        InventoriesProductsandworkinProgressTok: Label 'Inventories, Products and work in Progress', MaxLength = 100;
        RawMaterialsTok: Label 'Raw Materials', MaxLength = 100;
        SuppliesandConsumablesTok: Label 'Supplies and Consumables', MaxLength = 100;
        ProductsinProgressTok: Label 'Products in Progress', MaxLength = 100;
        FinishedGoodsTok: Label 'Finished Goods', MaxLength = 100;
        GoodsforResaleTok: Label 'Goods for Resale', MaxLength = 100;
        AdvancedPaymentsforgoodsandservicesTok: Label 'Advanced Payments for goods and services', MaxLength = 100;
        OtherInventoryItemsTok: Label 'Other Inventory Items', MaxLength = 100;
        WorkinProgressTok: Label 'Work in Progress', MaxLength = 100;
        WIPJobSalesTok: Label 'WIP Job Sales', MaxLength = 100;
        WIPJobCostsTok: Label 'WIP Job Costs', MaxLength = 100;
        WIPAccruedCostsTok: Label 'WIP, Accrued Costs', MaxLength = 100;
        WIPInvoicedSalesTok: Label 'WIP, Invoiced Sales', MaxLength = 100;
        TotalWorkinProgressTok: Label 'Total, Work in Progress', MaxLength = 100;
        TotalInventoryProductsandWorkinProgressTok: Label 'Total, Inventory, Products and Work in Progress', MaxLength = 100;
        ReceivablesTok: Label 'Receivables', MaxLength = 100;
        AccountReceivableDomesticTok: Label 'Account Receivable, Domestic', MaxLength = 100;
        AccountReceivableForeignTok: Label 'Account Receivable, Foreign', MaxLength = 100;
        ContractualReceivablesTok: Label 'Contractual Receivables', MaxLength = 100;
        CurrentReceivablefromEmployeesTok: Label 'Current Receivable from Employees', MaxLength = 100;
        ClearingAccountsforTaxesandchargesTok: Label 'Clearing Accounts for Taxes and charges', MaxLength = 100;
        TaxAssetsTok: Label 'Tax Assets', MaxLength = 100;
        PurchaseVATReducedTok: Label 'Purchase VAT Reduced', MaxLength = 100;
        PurchaseVATNormalTok: Label 'Purchase VAT Normal', MaxLength = 100;
        MiscVATReceivablesTok: Label 'Misc VAT Receivables', MaxLength = 100;
        CurrentReceivablesfromgroupcompaniesTok: Label 'Current Receivables from group companies', MaxLength = 100;
        TotalReceivablesTok: Label 'Total, Receivables', MaxLength = 100;
        PrepaidRentTok: Label 'Prepaid Rent', MaxLength = 100;
        AssetsintheformofprepaidexpensesTok: Label 'Assets in the form of prepaid expenses', MaxLength = 100;
        BondsTok: Label 'Bonds', MaxLength = 100;
        ConvertibledebtinstrumentsTok: Label 'Convertible debt instruments', MaxLength = 100;
        CashandBankTok: Label 'Cash and Bank', MaxLength = 100;
        PettyCashTok: Label 'Petty Cash', MaxLength = 100;
        BusinessaccountOperatingDomesticTok: Label 'Business account, Operating, Domestic', MaxLength = 100;
        BusinessaccountOperatingForeignTok: Label 'Business account, Operating, Foreign', MaxLength = 100;
        OtherbankaccountsTok: Label 'Other bank accounts ', MaxLength = 100;
        CertificateofDepositTok: Label 'Certificate of Deposit', MaxLength = 100;
        TotalCashandBankTok: Label 'Total, Cash and Bank', MaxLength = 100;
        TotalAssetsTok: Label 'Total Assets', MaxLength = 100;
        LiabilityTok: Label 'Liability', MaxLength = 100;
        BondsandDebentureLoansTok: Label 'Bonds and Debenture Loans', MaxLength = 100;
        ConvertiblesLoansTok: Label 'Convertibles Loans', MaxLength = 100;
        OtherLong_termLiabilitiesTok: Label 'Other Long-term Liabilities', MaxLength = 100;
        BankoverdraftFacilitiesTok: Label 'Bank overdraft Facilities', MaxLength = 100;
        AccountsPayableDomesticTok: Label 'Accounts Payable, Domestic', MaxLength = 100;
        AccountsPayableForeignTok: Label 'Accounts Payable, Foreign', MaxLength = 100;
        AdvancesfromcustomersTok: Label 'Advances from customers', MaxLength = 100;
        Bankoverdraftshort_termTok: Label 'Bank overdraft short-term', MaxLength = 100;
        OtherLiabilitiesTok: Label 'Other Liabilities', MaxLength = 100;
        DeferredRevenueTok: Label 'Deferred Revenue', MaxLength = 100;
        TaxesLiableTok: Label 'Taxes Liable', MaxLength = 100;
        SalesVATReducedTok: Label 'Sales VAT Reduced', MaxLength = 100;
        SalesVATNormalTok: Label 'Sales VAT Normal', MaxLength = 100;
        MiscVATPayablesTok: Label 'Misc VAT Payables', MaxLength = 100;
        EstimatedIncomeTaxTok: Label 'Estimated Income Tax', MaxLength = 100;
        EstimatedPayrolltaxonPensionCostsTok: Label 'Estimated Payroll tax on Pension Costs', MaxLength = 100;
        EmployeesWithholdingTaxesTok: Label 'Employees Withholding Taxes', MaxLength = 100;
        StatutorySocialsecurityContributionsTok: Label 'Statutory Social security Contributions', MaxLength = 100;
        AttachmentsofEarningTok: Label 'Attachments of Earning', MaxLength = 100;
        HolidayPayfundTok: Label 'Holiday Pay fund', MaxLength = 100;
        CurrentLiabilitiestoEmployeesTok: Label 'Current Liabilities to Employees', MaxLength = 100;
        CurrentLoansTok: Label 'Current Loans', MaxLength = 100;
        TotalLiabilitiesTok: Label 'Total Liabilities', MaxLength = 100;
        EquityTok: Label 'Equity', MaxLength = 100;
        EquityPartnerTok: Label 'Equity Partner ', MaxLength = 100;
        ShareCapitalTok: Label 'Share Capital ', MaxLength = 100;
        ProfitorlossfromthepreviousyearTok: Label 'Profit or loss from the previous year', MaxLength = 100;
        DistributionstoShareholdersTok: Label 'Distributions to Shareholders', MaxLength = 100;
        TotalEquityTok: Label 'Total, Equity', MaxLength = 100;
        INCOMESTATEMENTTok: Label 'INCOME STATEMENT', MaxLength = 100;
        IncomeTok: Label 'Income', MaxLength = 100;
        SalesofGoodsTok: Label 'Sales of Goods', MaxLength = 100;
        SaleofFinishedGoodsTok: Label 'Sale of Finished Goods', MaxLength = 100;
        SaleofRawMaterialsTok: Label 'Sale of Raw Materials', MaxLength = 100;
        ResaleofGoodsTok: Label 'Resale of Goods', MaxLength = 100;
        TotalSalesofGoodsTok: Label 'Total, Sales of Goods', MaxLength = 100;
        SalesofResourcesTok: Label 'Sales of Resources', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resources', MaxLength = 100;
        SaleofSubcontractingTok: Label 'Sale of Subcontracting', MaxLength = 100;
        TotalSalesofResourcesTok: Label 'Total, Sales of Resources', MaxLength = 100;
        IncomefromsecuritiesTok: Label 'Income from securities', MaxLength = 100;
        ManagementFeeRevenueTok: Label 'Management Fee Revenue', MaxLength = 100;
        InterestIncomeTok: Label 'Interest Income', MaxLength = 100;
        CurrencyGainsTok: Label 'Currency Gains', MaxLength = 100;
        OtherIncidentalRevenueTok: Label 'Other Incidental Revenue', MaxLength = 100;
        JobsandServicesTok: Label 'Jobs and Services', MaxLength = 100;
        JobSalesTok: Label 'Job Sales', MaxLength = 100;
        JobSalesAppliedTok: Label 'Job Sales Applied', MaxLength = 100;
        SalesofServiceContractsTok: Label 'Sales of Service Contracts', MaxLength = 100;
        SalesofServiceWorkTok: Label 'Sales of Service Work', MaxLength = 100;
        TotalJobsandServicesTok: Label 'Total, Jobs and Services', MaxLength = 100;
        RevenueReductionsTok: Label 'Revenue Reductions', MaxLength = 100;
        SalesDiscountsTok: Label 'Sales Discounts', MaxLength = 100;
        SalesInvoiceRoundingTok: Label 'Sales Invoice Rounding', MaxLength = 100;
        SalesReturnsTok: Label 'Sales Returns', MaxLength = 100;
        TotalRevenueReductionsTok: Label 'Total, Revenue Reductions', MaxLength = 100;
        TOTALINCOMETok: Label 'TOTAL INCOME', MaxLength = 100;
        COSTOFGOODSSOLDTok: Label 'COST OF GOODS SOLD', MaxLength = 100;
        CostofGoodsTok: Label 'Cost of Goods', MaxLength = 100;
        CostofMaterialsTok: Label 'Cost of Materials', MaxLength = 100;
        CostofMaterialsProjectsTok: Label 'Cost of Materials, Projects', MaxLength = 100;
        TotalCostofGoodsTok: Label 'Total, Cost of Goods', MaxLength = 100;
        CostofResourcesandServicesTok: Label 'Cost of Resources and Services', MaxLength = 100;
        CostofLaborTok: Label 'Cost of Labor', MaxLength = 100;
        CostofLaborProjectsTok: Label 'Cost of Labor, Projects', MaxLength = 100;
        CostofLaborWarranty_ContractTok: Label 'Cost of Labor, Warranty/Contract', MaxLength = 100;
        TotalCostofResourcesTok: Label 'Total, Cost of Resources', MaxLength = 100;
        CostsofJobsTok: Label 'Costs of Jobs', MaxLength = 100;
        JobCostsTok: Label 'Job Costs', MaxLength = 100;
        JobCostsAppliedTok: Label 'Job Costs, Applied', MaxLength = 100;
        TotalCostsofJobsTok: Label 'Total, Costs of Jobs', MaxLength = 100;
        SubcontractedworkTok: Label 'Subcontracted work', MaxLength = 100;
        ManufVariancesTok: Label 'Manuf. Variances', MaxLength = 100;
        PurchaseVarianceCapTok: Label 'Purchase Variance, Cap.', MaxLength = 100;
        MaterialVarianceTok: Label 'Material Variance', MaxLength = 100;
        CapacityVarianceTok: Label 'Capacity Variance', MaxLength = 100;
        SubcontractedVarianceTok: Label 'Subcontracted Variance', MaxLength = 100;
        CapOverheadVarianceTok: Label 'Cap. Overhead Variance', MaxLength = 100;
        MfgOverheadVarianceTok: Label 'Mfg. Overhead Variance', MaxLength = 100;
        TotalManufVariancesTok: Label 'Total, Manuf. Variances', MaxLength = 100;
        CostofVariancesTok: Label 'Cost of Variances', MaxLength = 100;
        TOTALCOSTOFGOODSSOLDTok: Label 'TOTAL COST OF GOODS SOLD', MaxLength = 100;
        EXPENSESTok: Label 'EXPENSES', MaxLength = 100;
        RentalFacilitiesTok: Label 'Rental Facilities', MaxLength = 100;
        Rent_LeasesTok: Label 'Rent / Leases', MaxLength = 100;
        ElectricityforRentalTok: Label 'Electricity for Rental', MaxLength = 100;
        HeatingforRentalTok: Label 'Heating for Rental', MaxLength = 100;
        WaterandSewerageforRentalTok: Label 'Water and Sewerage for Rental', MaxLength = 100;
        CleaningandWasteforRentalTok: Label 'Cleaning and Waste for Rental', MaxLength = 100;
        RepairsandMaintenanceforRentalTok: Label 'Repairs and Maintenance for Rental', MaxLength = 100;
        InsurancesRentalTok: Label 'Insurances, Rental', MaxLength = 100;
        OtherRentalExpensesTok: Label 'Other Rental Expenses', MaxLength = 100;
        TotalRentalFacilitiesTok: Label 'Total, Rental Facilities', MaxLength = 100;
        HireofmachineryTok: Label 'Hire of machinery', MaxLength = 100;
        HireofcomputersTok: Label 'Hire of computers', MaxLength = 100;
        HireofotherfixedassetsTok: Label 'Hire of other fixed assets', MaxLength = 100;
        PassengerCarCostsTok: Label 'Passenger Car Costs', MaxLength = 100;
        TruckCostsTok: Label 'Truck Costs', MaxLength = 100;
        OthervehicleexpensesTok: Label 'Other vehicle expenses', MaxLength = 100;
        FreightfeesforgoodsTok: Label 'Freight fees for goods', MaxLength = 100;
        CustomsandforwardingTok: Label 'Customs and forwarding', MaxLength = 100;
        FreightfeesprojectsTok: Label 'Freight fees, projects', MaxLength = 100;
        TravelExpensesTok: Label 'Travel Expenses', MaxLength = 100;
        TicketsTok: Label 'Tickets', MaxLength = 100;
        RentalvehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        BoardandlodgingTok: Label 'Board and lodging', MaxLength = 100;
        OthertravelexpensesTok: Label 'Other travel expenses', MaxLength = 100;
        TotalTravelExpensesTok: Label 'Total, Travel Expenses', MaxLength = 100;
        AdvertisementDevelopmentTok: Label 'Advertisement Development', MaxLength = 100;
        OutdoorandTransportationAdsTok: Label 'Outdoor and Transportation Ads', MaxLength = 100;
        AdmatteranddirectmailingsTok: Label 'Ad matter and direct mailings', MaxLength = 100;
        Conference_ExhibitionSponsorshipTok: Label 'Conference/Exhibition Sponsorship', MaxLength = 100;
        SamplescontestsgiftsTok: Label 'Samples, contests, gifts', MaxLength = 100;
        FilmTVradiointernetadsTok: Label 'Film, TV, radio, internet ads', MaxLength = 100;
        CreditCardChargesTok: Label 'Credit Card Charges', MaxLength = 100;
        BusinessEntertainingdeductibleTok: Label 'Business Entertaining, deductible', MaxLength = 100;
        BusinessEntertainingnondeductibleTok: Label 'Business Entertaining, nondeductible', MaxLength = 100;
        OfficeSuppliesTok: Label 'Office Supplies', MaxLength = 100;
        PhoneServicesTok: Label 'Phone Services', MaxLength = 100;
        DataservicesTok: Label 'Data services', MaxLength = 100;
        PostalfeesTok: Label 'Postal fees', MaxLength = 100;
        Consumable_ExpensiblehardwareTok: Label 'Consumable/Expensible hardware', MaxLength = 100;
        SoftwareandsubscriptionfeesTok: Label 'Software and subscription fees', MaxLength = 100;
        CorporateInsuranceTok: Label 'Corporate Insurance', MaxLength = 100;
        BadDebtLossesTok: Label 'Bad Debt Losses', MaxLength = 100;
        Annual_interrimReportsTok: Label 'Annual/interrim Reports', MaxLength = 100;
        PayableInvoiceRoundingTok: Label 'Payable Invoice Rounding', MaxLength = 100;
        AccountingServicesTok: Label 'Accounting Services', MaxLength = 100;
        LegalFeesandAttorneyServicesTok: Label 'Legal Fees and Attorney Services', MaxLength = 100;
        OtherExternalServicesTok: Label 'Other External Services', MaxLength = 100;
        MiscexternalexpensesTok: Label 'Misc. external expenses', MaxLength = 100;
        PurchaseDiscountsTok: Label 'Purchase Discounts', MaxLength = 100;
        PersonnelTok: Label 'Personnel', MaxLength = 100;
        SalariesTok: Label 'Salaries', MaxLength = 100;
        HourlyWagesTok: Label 'Hourly Wages', MaxLength = 100;
        OvertimeWagesTok: Label 'Overtime Wages', MaxLength = 100;
        BonusesTok: Label 'Bonuses', MaxLength = 100;
        CommissionsPaidTok: Label 'Commissions Paid', MaxLength = 100;
        PensionfeesandrecurringcostsTok: Label 'Pension fees and recurring costs', MaxLength = 100;
        EmployerContributionsTok: Label 'Employer Contributions', MaxLength = 100;
        HealthInsuranceTok: Label 'Health Insurance', MaxLength = 100;
        TotalPersonnelTok: Label 'Total, Personnel', MaxLength = 100;
        DepreciationLandandPropertyTok: Label 'Depreciation, Land and Property', MaxLength = 100;
        DepreciationFixedAssetsTok: Label 'Depreciation, Fixed Assets', MaxLength = 100;
        CurrencyLossesTok: Label 'Currency Losses', MaxLength = 100;
        TOTALEXPENSESTok: Label 'TOTAL EXPENSES', MaxLength = 100;
        NETINCOMETok: Label 'NET INCOME', MaxLength = 100;

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
        AddCategoriesToGLAccountsForMini();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 1000-4999
        DemoDataSetup.Get();
        InsertData(INCOMESTATEMENT(), INCOMESTATEMENTName(), 1, 0, 1, '', 0, '', '', '', '', true);
        InsertData(Income(), IncomeName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofGoods(), SalesofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofFinishedGoods(), SaleofFinishedGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(SaleofRawMaterials(), SaleofRawMaterialsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(ResaleofGoods(), ResaleofGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(TotalSalesofGoods(), TotalSalesofGoodsName(), 4, 0, 0, '4400..4409', 0, '', '', '', '', true);
        InsertData(SalesofResources(), SalesofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofResources(), SaleofResourcesName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SaleofSubcontracting(), SaleofSubcontractingName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(TotalSalesofResources(), TotalSalesofResourcesName(), 4, 0, 0, '4410..4413', 0, '', '', '', '', true);
        InsertData(Incomefromsecurities(), IncomefromsecuritiesName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData(ManagementFeeRevenue(), ManagementFeeRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(InterestIncome(), InterestIncomeName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(CurrencyGains(), CurrencyGainsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(OtherIncidentalRevenue(), OtherIncidentalRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(JobsandServices(), JobsandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSales(), JobSalesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(JobSalesApplied(), JobSalesAppliedName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesofServiceContracts(), SalesofServiceContractsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SalesofServiceWork(), SalesofServiceWorkName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalJobsandServices(), TotalJobsandServicesName(), 4, 0, 0, '4414..4419', 0, '', '', '', '', true);
        InsertData(RevenueReductions(), RevenueReductionsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesDiscounts(), SalesDiscountsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesInvoiceRounding(), SalesInvoiceRoundingName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesReturns(), SalesReturnsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalRevenueReductions(), TotalRevenueReductionsName(), 4, 0, 0, '4700..4799', 0, '', '', '', '', true);
        InsertData(TOTALINCOME(), TOTALINCOMEName(), 4, 0, 0, '4000..4999', 0, '', '', '', '', true);
        InsertData(COSTOFGOODSSOLD(), COSTOFGOODSSOLDName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofGoods(), CostofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterials(), CostofMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterialsProjects(), CostofMaterialsProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofGoods(), TotalCostofGoodsName(), 4, 0, 0, '5020..5023', 0, '', '', '', '', true);
        InsertData(CostofResourcesandServices(), CostofResourcesandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLabor(), CostofLaborName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborProjects(), CostofLaborProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborWarranty_Contract(), CostofLaborWarranty_ContractName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofResources(), TotalCostofResourcesName(), 4, 0, 0, '5900..5905', 0, '', '', '', '', true);
        InsertData(CostsofJobs(), CostsofJobsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCosts(), JobCostsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostsApplied(), JobCostsAppliedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostsofJobs(), TotalCostsofJobsName(), 4, 0, 0, '5040..5043', 0, '', '', '', '', true);
        InsertData(Subcontractedwork(), SubcontractedworkName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ManufVariances(), ManufVariancesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVarianceCap(), PurchaseVarianceCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MaterialVariance(), MaterialVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapacityVariance(), CapacityVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SubcontractedVariance(), SubcontractedVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapOverheadVariance(), CapOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MfgOverheadVariance(), MfgOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalManufVariances(), TotalManufVariancesName(), 4, 0, 0, '5030..5038', 0, '', '', '', '', true);
        InsertData(CostofVariances(), CostofVariancesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALCOSTOFGOODSSOLD(), TOTALCOSTOFGOODSSOLDName(), 4, 0, 0, '5..5999', 0, '', '', '', '', true);
        InsertData(EXPENSES(), EXPENSESName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RentalFacilities(), RentalFacilitiesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Rent_Leases(), Rent_LeasesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ElectricityforRental(), ElectricityforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HeatingforRental(), HeatingforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WaterandSewerageforRental(), WaterandSewerageforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CleaningandWasteforRental(), CleaningandWasteforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RepairsandMaintenanceforRental(), RepairsandMaintenanceforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesRental(), InsurancesRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherRentalExpenses(), OtherRentalExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalRentalFacilities(), TotalRentalFacilitiesName(), 4, 0, 0, '6300..6399', 1, '', '', '', '', true);
        InsertData(Hireofmachinery(), HireofmachineryName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofcomputers(), HireofcomputersName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofotherfixedassets(), HireofotherfixedassetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PassengerCarCosts(), PassengerCarCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TruckCosts(), TruckCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othervehicleexpenses(), OthervehicleexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesforgoods(), FreightfeesforgoodsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Customsandforwarding(), CustomsandforwardingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesprojects(), FreightfeesprojectsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TravelExpenses(), TravelExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Tickets(), TicketsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Rentalvehicles(), RentalvehiclesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Boardandlodging(), BoardandlodgingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othertravelexpenses(), OthertravelexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalTravelExpenses(), TotalTravelExpensesName(), 4, 0, 0, '6649..6669', 1, '', '', '', '', true);
        InsertData(AdvertisementDevelopment(), AdvertisementDevelopmentName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OutdoorandTransportationAds(), OutdoorandTransportationAdsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Admatteranddirectmailings(), AdmatteranddirectmailingsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Conference_ExhibitionSponsorship(), Conference_ExhibitionSponsorshipName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Samplescontestsgifts(), SamplescontestsgiftsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FilmTVradiointernetads(), FilmTVradiointernetadsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CreditCardCharges(), CreditCardChargesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingdeductible(), BusinessEntertainingdeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingnondeductible(), BusinessEntertainingnondeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OfficeSupplies(), OfficeSuppliesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PhoneServices(), PhoneServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Dataservices(), DataservicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Postalfees(), PostalfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Consumable_Expensiblehardware(), Consumable_ExpensiblehardwareName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Softwareandsubscriptionfees(), SoftwareandsubscriptionfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CorporateInsurance(), CorporateInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BadDebtLosses(), BadDebtLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Annual_interrimReports(), Annual_interrimReportsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PayableInvoiceRounding(), PayableInvoiceRoundingName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(AccountingServices(), AccountingServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LegalFeesandAttorneyServices(), LegalFeesandAttorneyServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherExternalServices(), OtherExternalServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Miscexternalexpenses(), MiscexternalexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PurchaseDiscounts(), PurchaseDiscountsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Personnel(), PersonnelName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Salaries(), SalariesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HourlyWages(), HourlyWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OvertimeWages(), OvertimeWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Bonuses(), BonusesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CommissionsPaid(), CommissionsPaidName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Pensionfeesandrecurringcosts(), PensionfeesandrecurringcostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(EmployerContributions(), EmployerContributionsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HealthInsurance(), HealthInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPersonnel(), TotalPersonnelName(), 4, 0, 0, '6001..6199', 1, '', '', '', '', true);
        InsertData(DepreciationLandandProperty(), DepreciationLandandPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DepreciationFixedAssets(), DepreciationFixedAssetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CurrencyLosses(), CurrencyLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TOTALEXPENSES(), TOTALEXPENSESName(), 4, 0, 0, '6..7999', 1, '', '', '', '', true);
        InsertData(NETINCOME(), NETINCOMEName(), 2, 0, 0, '', 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData(BalanceSheet(), BalanceSheetName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(Assets(), AssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DevelopmentExpenditure(), DevelopmentExpenditureName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TenancySiteLeaseholdandsimilarrights(), TenancySiteLeaseholdandsimilarrightsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Goodwill(), GoodwillName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforIntangibleFixedAssets(), AdvancedPaymentsforIntangibleFixedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Building(), BuildingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CostofImprovementstoLeasedProperty(), CostofImprovementstoLeasedPropertyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Land(), LandName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquipmentsandTools(), EquipmentsandToolsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Computers(), ComputersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CarsandotherTransportEquipments(), CarsandotherTransportEquipmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LeasedAssets(), LeasedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccumulatedDepreciation(), AccumulatedDepreciationName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Long_termReceivables(), Long_termReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ParticipationinGroupCompanies(), ParticipationinGroupCompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LoanstoPartnersorrelatedParties(), LoanstoPartnersorrelatedPartiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredTaxAssets(), DeferredTaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InventoriesProductsandworkinProgress(), InventoriesProductsandworkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RawMaterials(), RawMaterialsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SuppliesandConsumables(), SuppliesandConsumablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ProductsinProgress(), ProductsinProgressName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinishedGoods(), FinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GoodsforResale(), GoodsforResaleName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforgoodsandservices(), AdvancedPaymentsforgoodsandservicesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherInventoryItems(), OtherInventoryItemsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WorkinProgress(), WorkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobSales(), WIPJobSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobCosts(), WIPJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPAccruedCosts(), WIPAccruedCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPInvoicedSales(), WIPInvoicedSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalWorkinProgress(), TotalWorkinProgressName(), 4, 1, 0, '1080..1089', 0, '', '', '', '', true);
        InsertData(TotalInventoryProductsandWorkinProgress(), TotalInventoryProductsandWorkinProgressName(), 4, 1, 0, '1000..1099', 0, '', '', '', '', true);
        InsertData(Receivables(), ReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableDomestic(), AccountReceivableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableForeign(), AccountReceivableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ContractualReceivables(), ContractualReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablefromEmployees(), CurrentReceivablefromEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountsforTaxesandcharges(), ClearingAccountsforTaxesandchargesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxAssets(), TaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVATReduced(), PurchaseVATReducedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVATNormal(), PurchaseVATNormalName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(MiscVATReceivables(), MiscVATReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablesfromgroupcompanies(), CurrentReceivablesfromgroupcompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalReceivables(), TotalReceivablesName(), 4, 1, 0, '1200..1499', 0, '', '', '', '', true);
        InsertData(PrepaidRent(), PrepaidRentName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Assetsintheformofprepaidexpenses(), AssetsintheformofprepaidexpensesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bonds(), BondsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Convertibledebtinstruments(), ConvertibledebtinstrumentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CashandBank(), CashandBankName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PettyCash(), PettyCashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BusinessaccountOperatingDomestic(), BusinessaccountOperatingDomesticName(), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData(BusinessaccountOperatingForeign(), BusinessaccountOperatingForeignName(), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData(Otherbankaccounts(), OtherbankaccountsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CertificateofDeposit(), CertificateofDepositName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCashandBank(), TotalCashandBankName(), 4, 1, 0, '1600..1899', 0, '', '', '', '', true);
        InsertData(TotalAssets(), TotalAssetsName(), 4, 1, 0, '00..1999', 0, '', '', '', '', true);
        InsertData(Liability(), LiabilityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BondsandDebentureLoans(), BondsandDebentureLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ConvertiblesLoans(), ConvertiblesLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLong_termLiabilities(), OtherLong_termLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankoverdraftFacilities(), BankoverdraftFacilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableDomestic(), AccountsPayableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableForeign(), AccountsPayableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Advancesfromcustomers(), AdvancesfromcustomersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bankoverdraftshort_term(), Bankoverdraftshort_termName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLiabilities(), OtherLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredRevenue(), DeferredRevenueName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxesLiable(), TaxesLiableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesVATReducedPayable(), SalesVATReducedPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesVATNormalPayable(), SalesVATNormalPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(MiscVATPayable(), MiscVATPayableName(), 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(EstimatedIncomeTax(), EstimatedIncomeTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EstimatedPayrolltaxonPensionCosts(), EstimatedPayrolltaxonPensionCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EmployeesWithholdingTaxes(), EmployeesWithholdingTaxesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(StatutorySocialsecurityContributions(), StatutorySocialsecurityContributionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AttachmentsofEarning(), AttachmentsofEarningName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(HolidayPayfund(), HolidayPayfundName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLiabilitiestoEmployees(), CurrentLiabilitiestoEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLoans(), CurrentLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLiabilities(), TotalLiabilitiesName(), 4, 1, 0, '3..3999', 0, '', '', '', '', true);
        InsertData(Equity(), EquityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquityPartner(), EquityPartnerName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ShareCapital(), ShareCapitalName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Profitorlossfromthepreviousyear(), ProfitorlossfromthepreviousyearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DistributionstoShareholders(), DistributionstoShareholdersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalEquity(), TotalEquityName(), 4, 1, 0, '2..2999', 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", AccountNo);
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        case AccountNo of
            '1005', '1210', '1230', '1220', '1290', PettyCash():
                GLAccount."Reconciliation Account" := true;
            '5999':
                GLAccount."New Page" := true;
        end;
        GLAccount.Validate("No. of Blank Lines", NoOfBlankLines);
        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        if GenPostingType > 0 then
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
        if GenBusPostingGroup <> '' then
            GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if GenProdPostingGroup <> '' then
            GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if VATGenPostingGroup <> '' then
            GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
        if VATProdPostingGroup <> '' then
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("Consol. Debit Acc.", GLAccount."No.");
        GLAccount.Validate("Consol. Credit Acc.", GLAccount."No.");
        GLAccount.Insert();
    end;

    procedure AddCategoriesToGLAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccounts(GLAccountCategory);
                AssignCategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccounts(GLAccountCategory);
                AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    procedure AssignCategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                begin
                    UpdateGLAccounts(GLAccountCategory, '0000', '0596');
                    UpdateGLAccounts(GLAccountCategory, '0949', '1598');
                    UpdateGLAccounts(GLAccountCategory, '4831', '4884');
                end;
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '0599', '0789');
                    UpdateGLAccounts(GLAccountCategory, '1600', '1798');
                end;
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '0790', '0948');
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '3700', '3796');
                    UpdateGLAccounts(GLAccountCategory, '8000', '8840');
                    UpdateGLAccounts(GLAccountCategory, '995795', '996959');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                begin
                    UpdateGLAccounts(GLAccountCategory, '2889', '3698');
                    UpdateGLAccounts(GLAccountCategory, '3799', '4098');
                    UpdateGLAccounts(GLAccountCategory, '4995', '7149');
                    UpdateGLAccounts(GLAccountCategory, '8959', '8995');
                end;
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '1799', '2879');
                    UpdateGLAccounts(GLAccountCategory, '4099', '4812');
                    UpdateGLAccounts(GLAccountCategory, '4885', '4994');
                    UpdateGLAccounts(GLAccountCategory, '8900', '8956');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCurrentAssets():
                UpdateGLAccounts(GLAccountCategory, '0949', '0998');
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '1000', '1391');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '1400', '1598');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                ;
            GLAccountCategoryMgt.GetInventory():
                ;
            GLAccountCategoryMgt.GetEquipment():
                ;
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '4831', '4884');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '1600', '1704');
                    UpdateGLAccounts(GLAccountCategory, '1709', '1738');
                    UpdateGLAccounts(GLAccountCategory, '1757', '1798');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '1739', '1756');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '0599', '0789');
                    UpdateGLAccounts(GLAccountCategory, '1705', '1708');
                end;
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '0790', '0844');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '0845', '0869');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '0871', '0948');
            GLAccountCategoryMgt.GetIncomeService():
                ;
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '8000', '8405');
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                begin
                    UpdateGLAccounts(GLAccountCategory, '3700', '3796');
                    UpdateGLAccounts(GLAccountCategory, '8700', '8798');
                end;
            GLAccountCategoryMgt.GetIncomeSalesReturns():
                ;
            GLAccountCategoryMgt.GetIncomeInterest():
                UpdateGLAccounts(GLAccountCategory, '8649', '8699');
            GLAccountCategoryMgt.GetJobSalesContra():
                UpdateGLAccounts(GLAccountCategory, '8450', '8460');
            GLAccountCategoryMgt.GetCOGSLabor():
                ;
            GLAccountCategoryMgt.GetCOGSMaterials():
                begin
                    UpdateGLAccounts(GLAccountCategory, '2889', '3099');
                    UpdateGLAccounts(GLAccountCategory, '3200', '3698');
                    UpdateGLAccounts(GLAccountCategory, '3799', '4098');
                    UpdateGLAccounts(GLAccountCategory, '7000', '7149');
                    UpdateGLAccounts(GLAccountCategory, '8959', '8995');
                end;
            GLAccountCategoryMgt.GetJobsCost():
                begin
                    UpdateGLAccounts(GLAccountCategory, '3100', '3150');
                    UpdateGLAccounts(GLAccountCategory, '4995', '5999');
                end;
            GLAccountCategoryMgt.GetRentExpense():
                ;
            GLAccountCategoryMgt.GetAdvertisingExpense():
                ;
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '2100', '2177');
            GLAccountCategoryMgt.GetFeesExpense():
                ;
            GLAccountCategoryMgt.GetInsuranceExpense():
                ;
            GLAccountCategoryMgt.GetPayrollExpense():
                ;
            GLAccountCategoryMgt.GetBenefitsExpense():
                ;
            GLAccountCategoryMgt.GetSalariesExpense():
                UpdateGLAccounts(GLAccountCategory, '4099', '4198');
            GLAccountCategoryMgt.GetRepairsExpense():
                ;
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '4199', '4812');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '2300', '2879');
                    UpdateGLAccounts(GLAccountCategory, '4885', '4988');
                end;
            GLAccountCategoryMgt.GetTaxExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '2199', '2298');
                    UpdateGLAccounts(GLAccountCategory, '8900', '8956');
                end;
        end;
    end;

    local procedure UpdateGLAccounts(GLAccountCategory: Record "G/L Account Category"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not TryGetGLAccountNoRange(GLAccount, FromGLAccountNo, ToGLAccountNo) then
            exit;

        GLAccount.ModifyAll("Account Category", GLAccountCategory."Account Category", false);
        GLAccount.ModifyAll("Account Subcategory Entry No.", GLAccountCategory."Entry No.", false);
    end;

    [TryFunction]
    local procedure TryGetGLAccountNoRange(var GLAccount: Record "G/L Account"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        GLAccount.SetRange("No.", MakeAdjustments.Convert(FromGLAccountNo), MakeAdjustments.Convert(ToGLAccountNo));
    end;

    local procedure AssignCategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;

    local procedure AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;

    local procedure AddCategoriesToGLAccountsForMini()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccountsForMini(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    local procedure AssignCategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, '00', '1999');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '3', '3999');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '2', '2999');
            GLAccountCategory."Account Category"::Income:
                UpdateGLAccounts(GLAccountCategory, '4000', '4999');
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '5', '5999');
            GLAccountCategory."Account Category"::Expense:
                UpdateGLAccounts(GLAccountCategory, '6', '7999');
        end;
    end;

    local procedure AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '1600', '1990');
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '1000', '1099');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '1200', '1499');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '0490', '0490');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '2100', '2100');
            GLAccountCategoryMgt.GetIncomeService():
                UpdateGLAccounts(GLAccountCategory, '4410', '4413');
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '4400', '4409');
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '5900', '5905');
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '5020', '5023');
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '6310', '6310');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '4203', '4203');
            GLAccountCategoryMgt.GetBadDebtExpense():
                UpdateGLAccounts(GLAccountCategory, '6930', '6930');
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '6335', '6335');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '6325', '6330');
        end;
    end;

    internal procedure BalanceSheet(): Code[20]
    begin
        exit('0');
    end;

    internal procedure BalanceSheetName(): Text[100]
    begin
        exit(BalanceSheetTok);
    end;


    internal procedure Assets(): Code[20]
    begin
        exit('00');
    end;

    internal procedure AssetsName(): Text[100]
    begin
        exit(AssetsTok);
    end;


    internal procedure DevelopmentExpenditure(): Code[20]
    begin
        exit('0148');
    end;

    internal procedure DevelopmentExpenditureName(): Text[100]
    begin
        exit(DevelopmentExpenditureTok);
    end;


    internal procedure TenancySiteLeaseholdandsimilarrights(): Code[20]
    begin
        exit('0220');
    end;

    internal procedure TenancySiteLeaseholdandsimilarrightsName(): Text[100]
    begin
        exit(TenancySiteLeaseholdandsimilarrightsTok);
    end;


    internal procedure Goodwill(): Code[20]
    begin
        exit('0150');
    end;

    internal procedure GoodwillName(): Text[100]
    begin
        exit(GoodwillTok);
    end;


    internal procedure AdvancedPaymentsforIntangibleFixedAssets(): Code[20]
    begin
        exit('0170');
    end;

    internal procedure AdvancedPaymentsforIntangibleFixedAssetsName(): Text[100]
    begin
        exit(AdvancedPaymentsforIntangibleFixedAssetsTok);
    end;


    internal procedure Building(): Code[20]
    begin
        exit('0260');
    end;

    internal procedure BuildingName(): Text[100]
    begin
        exit(BuildingTok);
    end;


    internal procedure CostofImprovementstoLeasedProperty(): Code[20]
    begin
        exit('0290');
    end;

    internal procedure CostofImprovementstoLeasedPropertyName(): Text[100]
    begin
        exit(CostofImprovementstoLeasedPropertyTok);
    end;


    internal procedure Land(): Code[20]
    begin
        exit('0200');
    end;

    internal procedure LandName(): Text[100]
    begin
        exit(LandTok);
    end;


    internal procedure EquipmentsandTools(): Code[20]
    begin
        exit('0400');
    end;

    internal procedure EquipmentsandToolsName(): Text[100]
    begin
        exit(EquipmentsandToolsTok);
    end;


    internal procedure Computers(): Code[20]
    begin
        exit('0635');
    end;

    internal procedure ComputersName(): Text[100]
    begin
        exit(ComputersTok);
    end;


    internal procedure CarsandotherTransportEquipments(): Code[20]
    begin
        exit('0520');
    end;

    internal procedure CarsandotherTransportEquipmentsName(): Text[100]
    begin
        exit(CarsandotherTransportEquipmentsTok);
    end;


    internal procedure LeasedAssets(): Code[20]
    begin
        exit('0510');
    end;

    internal procedure LeasedAssetsName(): Text[100]
    begin
        exit(LeasedAssetsTok);
    end;


    internal procedure AccumulatedDepreciation(): Code[20]
    begin
        exit('0490');
    end;

    internal procedure AccumulatedDepreciationName(): Text[100]
    begin
        exit(AccumulatedDepreciationTok);
    end;


    internal procedure Long_termReceivables(): Code[20]
    begin
        exit('1225');
    end;

    internal procedure Long_termReceivablesName(): Text[100]
    begin
        exit(Long_termReceivablesTok);
    end;


    internal procedure ParticipationinGroupCompanies(): Code[20]
    begin
        exit('0804');
    end;

    internal procedure ParticipationinGroupCompaniesName(): Text[100]
    begin
        exit(ParticipationinGroupCompaniesTok);
    end;


    internal procedure LoanstoPartnersorrelatedParties(): Code[20]
    begin
        exit('0814');
    end;

    internal procedure LoanstoPartnersorrelatedPartiesName(): Text[100]
    begin
        exit(LoanstoPartnersorrelatedPartiesTok);
    end;


    internal procedure DeferredTaxAssets(): Code[20]
    begin
        exit('1950');
    end;

    internal procedure DeferredTaxAssetsName(): Text[100]
    begin
        exit(DeferredTaxAssetsTok);
    end;


    internal procedure InventoriesProductsandworkinProgress(): Code[20]
    begin
        exit('1000');
    end;

    internal procedure InventoriesProductsandworkinProgressName(): Text[100]
    begin
        exit(InventoriesProductsandworkinProgressTok);
    end;


    internal procedure RawMaterials(): Code[20]
    begin
        exit('1001');
    end;

    internal procedure RawMaterialsName(): Text[100]
    begin
        exit(RawMaterialsTok);
    end;


    internal procedure SuppliesandConsumables(): Code[20]
    begin
        exit('1002');
    end;

    internal procedure SuppliesandConsumablesName(): Text[100]
    begin
        exit(SuppliesandConsumablesTok);
    end;


    internal procedure ProductsinProgress(): Code[20]
    begin
        exit('1051');
    end;

    internal procedure ProductsinProgressName(): Text[100]
    begin
        exit(ProductsinProgressTok);
    end;


    internal procedure FinishedGoods(): Code[20]
    begin
        exit('1101');
    end;

    internal procedure FinishedGoodsName(): Text[100]
    begin
        exit(FinishedGoodsTok);
    end;


    internal procedure GoodsforResale(): Code[20]
    begin
        exit('1102');
    end;

    internal procedure GoodsforResaleName(): Text[100]
    begin
        exit(GoodsforResaleTok);
    end;


    internal procedure AdvancedPaymentsforgoodsandservices(): Code[20]
    begin
        exit('1180');
    end;

    internal procedure AdvancedPaymentsforgoodsandservicesName(): Text[100]
    begin
        exit(AdvancedPaymentsforgoodsandservicesTok);
    end;


    internal procedure OtherInventoryItems(): Code[20]
    begin
        exit('1178');
    end;

    internal procedure OtherInventoryItemsName(): Text[100]
    begin
        exit(OtherInventoryItemsTok);
    end;


    internal procedure WorkinProgress(): Code[20]
    begin
        exit('1080');
    end;

    internal procedure WorkinProgressName(): Text[100]
    begin
        exit(WorkinProgressTok);
    end;


    internal procedure WIPJobSales(): Code[20]
    begin
        exit('1081');
    end;

    internal procedure WIPJobSalesName(): Text[100]
    begin
        exit(WIPJobSalesTok);
    end;


    internal procedure WIPJobCosts(): Code[20]
    begin
        exit('1082');
    end;

    internal procedure WIPJobCostsName(): Text[100]
    begin
        exit(WIPJobCostsTok);
    end;


    internal procedure WIPAccruedCosts(): Code[20]
    begin
        exit('1083');
    end;

    internal procedure WIPAccruedCostsName(): Text[100]
    begin
        exit(WIPAccruedCostsTok);
    end;


    internal procedure WIPInvoicedSales(): Code[20]
    begin
        exit('1084');
    end;

    internal procedure WIPInvoicedSalesName(): Text[100]
    begin
        exit(WIPInvoicedSalesTok);
    end;


    internal procedure TotalWorkinProgress(): Code[20]
    begin
        exit('1089');
    end;

    internal procedure TotalWorkinProgressName(): Text[100]
    begin
        exit(TotalWorkinProgressTok);
    end;


    internal procedure TotalInventoryProductsandWorkinProgress(): Code[20]
    begin
        exit('1099');
    end;

    internal procedure TotalInventoryProductsandWorkinProgressName(): Text[100]
    begin
        exit(TotalInventoryProductsandWorkinProgressTok);
    end;


    internal procedure Receivables(): Code[20]
    begin
        exit('1200');
    end;

    internal procedure ReceivablesName(): Text[100]
    begin
        exit(ReceivablesTok);
    end;


    internal procedure AccountReceivableDomestic(): Code[20]
    begin
        exit('1202');
    end;

    internal procedure AccountReceivableDomesticName(): Text[100]
    begin
        exit(AccountReceivableDomesticTok);
    end;


    internal procedure AccountReceivableForeign(): Code[20]
    begin
        exit('1203');
    end;

    internal procedure AccountReceivableForeignName(): Text[100]
    begin
        exit(AccountReceivableForeignTok);
    end;

    internal procedure ContractualReceivables(): Code[20]
    begin
        exit('1375');
    end;

    internal procedure ContractualReceivablesName(): Text[100]
    begin
        exit(ContractualReceivablesTok);
    end;


    internal procedure CurrentReceivablefromEmployees(): Code[20]
    begin
        exit('1340');
    end;

    internal procedure CurrentReceivablefromEmployeesName(): Text[100]
    begin
        exit(CurrentReceivablefromEmployeesTok);
    end;


    internal procedure ClearingAccountsforTaxesandcharges(): Code[20]
    begin
        exit('1480');
    end;

    internal procedure ClearingAccountsforTaxesandchargesName(): Text[100]
    begin
        exit(ClearingAccountsforTaxesandchargesTok);
    end;


    internal procedure TaxAssets(): Code[20]
    begin
        exit('1410');
    end;

    internal procedure TaxAssetsName(): Text[100]
    begin
        exit(TaxAssetsTok);
    end;


    internal procedure PurchaseVATReduced(): Code[20]
    begin
        exit('1403');
    end;

    internal procedure PurchaseVATReducedName(): Text[100]
    begin
        exit(PurchaseVATReducedTok);
    end;


    internal procedure PurchaseVATNormal(): Code[20]
    begin
        exit('1406');
    end;

    internal procedure PurchaseVATNormalName(): Text[100]
    begin
        exit(PurchaseVATNormalTok);
    end;


    internal procedure MiscVATReceivables(): Code[20]
    begin
        exit('1400');
    end;

    internal procedure MiscVATReceivablesName(): Text[100]
    begin
        exit(MiscVATReceivablesTok);
    end;


    internal procedure CurrentReceivablesfromgroupcompanies(): Code[20]
    begin
        exit('1260');
    end;

    internal procedure CurrentReceivablesfromgroupcompaniesName(): Text[100]
    begin
        exit(CurrentReceivablesfromgroupcompaniesTok);
    end;


    internal procedure TotalReceivables(): Code[20]
    begin
        exit('1499');
    end;

    internal procedure TotalReceivablesName(): Text[100]
    begin
        exit(TotalReceivablesTok);
    end;


    internal procedure PrepaidRent(): Code[20]
    begin
        exit('0750');
    end;

    internal procedure PrepaidRentName(): Text[100]
    begin
        exit(PrepaidRentTok);
    end;


    internal procedure Assetsintheformofprepaidexpenses(): Code[20]
    begin
        exit('1900');
    end;

    internal procedure AssetsintheformofprepaidexpensesName(): Text[100]
    begin
        exit(AssetsintheformofprepaidexpensesTok);
    end;


    internal procedure Bonds(): Code[20]
    begin
        exit('0920');
    end;

    internal procedure BondsName(): Text[100]
    begin
        exit(BondsTok);
    end;


    internal procedure Convertibledebtinstruments(): Code[20]
    begin
        exit('0940');
    end;

    internal procedure ConvertibledebtinstrumentsName(): Text[100]
    begin
        exit(ConvertibledebtinstrumentsTok);
    end;


    internal procedure CashandBank(): Code[20]
    begin
        exit('1600');
    end;

    internal procedure CashandBankName(): Text[100]
    begin
        exit(CashandBankTok);
    end;


    internal procedure PettyCash(): Code[20]
    begin
        exit('1610');
    end;

    internal procedure PettyCashName(): Text[100]
    begin
        exit(PettyCashTok);
    end;


    internal procedure BusinessaccountOperatingDomestic(): Code[20]
    begin
        exit('1810');
    end;

    internal procedure BusinessaccountOperatingDomesticName(): Text[100]
    begin
        exit(BusinessaccountOperatingDomesticTok);
    end;


    internal procedure BusinessaccountOperatingForeign(): Code[20]
    begin
        exit('1820');
    end;

    internal procedure BusinessaccountOperatingForeignName(): Text[100]
    begin
        exit(BusinessaccountOperatingForeignTok);
    end;


    internal procedure Otherbankaccounts(): Code[20]
    begin
        exit('1830');
    end;

    internal procedure OtherbankaccountsName(): Text[100]
    begin
        exit(OtherbankaccountsTok);
    end;


    internal procedure CertificateofDeposit(): Code[20]
    begin
        exit('1990');
    end;

    internal procedure CertificateofDepositName(): Text[100]
    begin
        exit(CertificateofDepositTok);
    end;


    internal procedure TotalCashandBank(): Code[20]
    begin
        exit('1899');
    end;

    internal procedure TotalCashandBankName(): Text[100]
    begin
        exit(TotalCashandBankTok);
    end;


    internal procedure TotalAssets(): Code[20]
    begin
        exit('1999');
    end;

    internal procedure TotalAssetsName(): Text[100]
    begin
        exit(TotalAssetsTok);
    end;


    internal procedure Liability(): Code[20]
    begin
        exit('3');
    end;

    internal procedure LiabilityName(): Text[100]
    begin
        exit(LiabilityTok);
    end;


    internal procedure BondsandDebentureLoans(): Code[20]
    begin
        exit('3100');
    end;

    internal procedure BondsandDebentureLoansName(): Text[100]
    begin
        exit(BondsandDebentureLoansTok);
    end;


    internal procedure ConvertiblesLoans(): Code[20]
    begin
        exit('3120');
    end;

    internal procedure ConvertiblesLoansName(): Text[100]
    begin
        exit(ConvertiblesLoansTok);
    end;


    internal procedure OtherLong_termLiabilities(): Code[20]
    begin
        exit('3150');
    end;

    internal procedure OtherLong_termLiabilitiesName(): Text[100]
    begin
        exit(OtherLong_termLiabilitiesTok);
    end;


    internal procedure BankoverdraftFacilities(): Code[20]
    begin
        exit('3151');
    end;

    internal procedure BankoverdraftFacilitiesName(): Text[100]
    begin
        exit(BankoverdraftFacilitiesTok);
    end;


    internal procedure AccountsPayableDomestic(): Code[20]
    begin
        exit('3301');
    end;

    internal procedure AccountsPayableDomesticName(): Text[100]
    begin
        exit(AccountsPayableDomesticTok);
    end;


    internal procedure AccountsPayableForeign(): Code[20]
    begin
        exit('3302');
    end;

    internal procedure AccountsPayableForeignName(): Text[100]
    begin
        exit(AccountsPayableForeignTok);
    end;


    internal procedure Advancesfromcustomers(): Code[20]
    begin
        exit('3250');
    end;

    internal procedure AdvancesfromcustomersName(): Text[100]
    begin
        exit(AdvancesfromcustomersTok);
    end;


    internal procedure Bankoverdraftshort_term(): Code[20]
    begin
        exit('3181');
    end;

    internal procedure Bankoverdraftshort_termName(): Text[100]
    begin
        exit(Bankoverdraftshort_termTok);
    end;


    internal procedure OtherLiabilities(): Code[20]
    begin
        exit('3500');
    end;

    internal procedure OtherLiabilitiesName(): Text[100]
    begin
        exit(OtherLiabilitiesTok);
    end;


    internal procedure DeferredRevenue(): Code[20]
    begin
        exit('3900');
    end;

    internal procedure DeferredRevenueName(): Text[100]
    begin
        exit(DeferredRevenueTok);
    end;


    internal procedure TaxesLiable(): Code[20]
    begin
        exit('3700');
    end;

    internal procedure TaxesLiableName(): Text[100]
    begin
        exit(TaxesLiableTok);
    end;


    internal procedure SalesVATReducedPayable(): Code[20]
    begin
        exit('3801');
    end;

    internal procedure SalesVATReducedPayableName(): Text[100]
    begin
        exit(SalesVATReducedTok);
    end;


    internal procedure SalesVATNormalPayable(): Code[20]
    begin
        exit('3806');
    end;

    internal procedure SalesVATNormalPayableName(): Text[100]
    begin
        exit(SalesVATNormalTok);
    end;


    internal procedure MiscVATPayable(): Code[20]
    begin
        exit('3800');
    end;

    internal procedure MiscVATPayableName(): Text[100]
    begin
        exit(MiscVATPayablesTok);
    end;


    internal procedure EstimatedIncomeTax(): Code[20]
    begin
        exit('3040');
    end;

    internal procedure EstimatedIncomeTaxName(): Text[100]
    begin
        exit(EstimatedIncomeTaxTok);
    end;


    internal procedure EstimatedPayrolltaxonPensionCosts(): Code[20]
    begin
        exit('3011');
    end;

    internal procedure EstimatedPayrolltaxonPensionCostsName(): Text[100]
    begin
        exit(EstimatedPayrolltaxonPensionCostsTok);
    end;


    internal procedure EmployeesWithholdingTaxes(): Code[20]
    begin
        exit('3720');
    end;

    internal procedure EmployeesWithholdingTaxesName(): Text[100]
    begin
        exit(EmployeesWithholdingTaxesTok);
    end;


    internal procedure StatutorySocialsecurityContributions(): Code[20]
    begin
        exit('3740');
    end;

    internal procedure StatutorySocialsecurityContributionsName(): Text[100]
    begin
        exit(StatutorySocialsecurityContributionsTok);
    end;


    internal procedure AttachmentsofEarning(): Code[20]
    begin
        exit('3725');
    end;

    internal procedure AttachmentsofEarningName(): Text[100]
    begin
        exit(AttachmentsofEarningTok);
    end;


    internal procedure HolidayPayfund(): Code[20]
    begin
        exit('3079');
    end;

    internal procedure HolidayPayfundName(): Text[100]
    begin
        exit(HolidayPayfundTok);
    end;


    internal procedure CurrentLiabilitiestoEmployees(): Code[20]
    begin
        exit('3721');
    end;

    internal procedure CurrentLiabilitiestoEmployeesName(): Text[100]
    begin
        exit(CurrentLiabilitiestoEmployeesTok);
    end;


    internal procedure CurrentLoans(): Code[20]
    begin
        exit('3560');
    end;

    internal procedure CurrentLoansName(): Text[100]
    begin
        exit(CurrentLoansTok);
    end;


    internal procedure TotalLiabilities(): Code[20]
    begin
        exit('3999');
    end;

    internal procedure TotalLiabilitiesName(): Text[100]
    begin
        exit(TotalLiabilitiesTok);
    end;


    internal procedure Equity(): Code[20]
    begin
        exit('2');
    end;

    internal procedure EquityName(): Text[100]
    begin
        exit(EquityTok);
    end;


    internal procedure EquityPartner(): Code[20]
    begin
        exit('2000');
    end;

    internal procedure EquityPartnerName(): Text[100]
    begin
        exit(EquityPartnerTok);
    end;


    internal procedure ShareCapital(): Code[20]
    begin
        exit('2010');
    end;

    internal procedure ShareCapitalName(): Text[100]
    begin
        exit(ShareCapitalTok);
    end;


    internal procedure Profitorlossfromthepreviousyear(): Code[20]
    begin
        exit('2970');
    end;

    internal procedure ProfitorlossfromthepreviousyearName(): Text[100]
    begin
        exit(ProfitorlossfromthepreviousyearTok);
    end;


    internal procedure DistributionstoShareholders(): Code[20]
    begin
        exit('2100');
    end;

    internal procedure DistributionstoShareholdersName(): Text[100]
    begin
        exit(DistributionstoShareholdersTok);
    end;


    internal procedure TotalEquity(): Code[20]
    begin
        exit('2999');
    end;

    internal procedure TotalEquityName(): Text[100]
    begin
        exit(TotalEquityTok);
    end;


    internal procedure INCOMESTATEMENT(): Code[20]
    begin
        exit('4');
    end;

    internal procedure INCOMESTATEMENTName(): Text[100]
    begin
        exit(INCOMESTATEMENTTok);
    end;


    internal procedure Income(): Code[20]
    begin
        exit('4000');
    end;

    internal procedure IncomeName(): Text[100]
    begin
        exit(IncomeTok);
    end;


    internal procedure SalesofGoods(): Code[20]
    begin
        exit('4400');
    end;

    internal procedure SalesofGoodsName(): Text[100]
    begin
        exit(SalesofGoodsTok);
    end;


    internal procedure SaleofFinishedGoods(): Code[20]
    begin
        exit('4401');
    end;

    internal procedure SaleofFinishedGoodsName(): Text[100]
    begin
        exit(SaleofFinishedGoodsTok);
    end;


    internal procedure SaleofRawMaterials(): Code[20]
    begin
        exit('4402');
    end;

    internal procedure SaleofRawMaterialsName(): Text[100]
    begin
        exit(SaleofRawMaterialsTok);
    end;


    internal procedure ResaleofGoods(): Code[20]
    begin
        exit('4403');
    end;

    internal procedure ResaleofGoodsName(): Text[100]
    begin
        exit(ResaleofGoodsTok);
    end;


    internal procedure TotalSalesofGoods(): Code[20]
    begin
        exit('4409');
    end;

    internal procedure TotalSalesofGoodsName(): Text[100]
    begin
        exit(TotalSalesofGoodsTok);
    end;


    internal procedure SalesofResources(): Code[20]
    begin
        exit('4410');
    end;

    internal procedure SalesofResourcesName(): Text[100]
    begin
        exit(SalesofResourcesTok);
    end;


    internal procedure SaleofResources(): Code[20]
    begin
        exit('4411');
    end;

    internal procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;


    internal procedure SaleofSubcontracting(): Code[20]
    begin
        exit('4412');
    end;

    internal procedure SaleofSubcontractingName(): Text[100]
    begin
        exit(SaleofSubcontractingTok);
    end;


    internal procedure TotalSalesofResources(): Code[20]
    begin
        exit('4413');
    end;

    internal procedure TotalSalesofResourcesName(): Text[100]
    begin
        exit(TotalSalesofResourcesTok);
    end;


    internal procedure Incomefromsecurities(): Code[20]
    begin
        exit('4201');
    end;

    internal procedure IncomefromsecuritiesName(): Text[100]
    begin
        exit(IncomefromsecuritiesTok);
    end;


    internal procedure ManagementFeeRevenue(): Code[20]
    begin
        exit('4202');
    end;

    internal procedure ManagementFeeRevenueName(): Text[100]
    begin
        exit(ManagementFeeRevenueTok);
    end;


    internal procedure InterestIncome(): Code[20]
    begin
        exit('4203');
    end;

    internal procedure InterestIncomeName(): Text[100]
    begin
        exit(InterestIncomeTok);
    end;


    internal procedure CurrencyGains(): Code[20]
    begin
        exit('4840');
    end;

    internal procedure CurrencyGainsName(): Text[100]
    begin
        exit(CurrencyGainsTok);
    end;


    internal procedure OtherIncidentalRevenue(): Code[20]
    begin
        exit('4830');
    end;

    internal procedure OtherIncidentalRevenueName(): Text[100]
    begin
        exit(OtherIncidentalRevenueTok);
    end;


    internal procedure JobsandServices(): Code[20]
    begin
        exit('4414');
    end;

    internal procedure JobsandServicesName(): Text[100]
    begin
        exit(JobsandServicesTok);
    end;


    internal procedure JobSales(): Code[20]
    begin
        exit('4415');
    end;

    internal procedure JobSalesName(): Text[100]
    begin
        exit(JobSalesTok);
    end;


    internal procedure JobSalesApplied(): Code[20]
    begin
        exit('4416');
    end;

    internal procedure JobSalesAppliedName(): Text[100]
    begin
        exit(JobSalesAppliedTok);
    end;


    internal procedure SalesofServiceContracts(): Code[20]
    begin
        exit('4417');
    end;

    internal procedure SalesofServiceContractsName(): Text[100]
    begin
        exit(SalesofServiceContractsTok);
    end;


    internal procedure SalesofServiceWork(): Code[20]
    begin
        exit('4418');
    end;

    internal procedure SalesofServiceWorkName(): Text[100]
    begin
        exit(SalesofServiceWorkTok);
    end;


    internal procedure TotalJobsandServices(): Code[20]
    begin
        exit('4419');
    end;

    internal procedure TotalJobsandServicesName(): Text[100]
    begin
        exit(TotalJobsandServicesTok);
    end;


    internal procedure RevenueReductions(): Code[20]
    begin
        exit('4700');
    end;

    internal procedure RevenueReductionsName(): Text[100]
    begin
        exit(RevenueReductionsTok);
    end;


    internal procedure SalesDiscounts(): Code[20]
    begin
        exit('4730');
    end;

    internal procedure SalesDiscountsName(): Text[100]
    begin
        exit(SalesDiscountsTok);
    end;


    internal procedure SalesInvoiceRounding(): Code[20]
    begin
        exit('7500');
    end;

    internal procedure SalesInvoiceRoundingName(): Text[100]
    begin
        exit(SalesInvoiceRoundingTok);
    end;


    internal procedure SalesReturns(): Code[20]
    begin
        exit('4770');
    end;

    internal procedure SalesReturnsName(): Text[100]
    begin
        exit(SalesReturnsTok);
    end;


    internal procedure TotalRevenueReductions(): Code[20]
    begin
        exit('4799');
    end;

    internal procedure TotalRevenueReductionsName(): Text[100]
    begin
        exit(TotalRevenueReductionsTok);
    end;


    internal procedure TOTALINCOME(): Code[20]
    begin
        exit('4999');
    end;

    internal procedure TOTALINCOMEName(): Text[100]
    begin
        exit(TOTALINCOMETok);
    end;


    internal procedure COSTOFGOODSSOLD(): Code[20]
    begin
        exit('5');
    end;

    internal procedure COSTOFGOODSSOLDName(): Text[100]
    begin
        exit(COSTOFGOODSSOLDTok);
    end;


    internal procedure CostofGoods(): Code[20]
    begin
        exit('5020');
    end;

    internal procedure CostofGoodsName(): Text[100]
    begin
        exit(CostofGoodsTok);
    end;


    internal procedure CostofMaterials(): Code[20]
    begin
        exit('5021');
    end;

    internal procedure CostofMaterialsName(): Text[100]
    begin
        exit(CostofMaterialsTok);
    end;


    internal procedure CostofMaterialsProjects(): Code[20]
    begin
        exit('5022');
    end;

    internal procedure CostofMaterialsProjectsName(): Text[100]
    begin
        exit(CostofMaterialsProjectsTok);
    end;


    internal procedure TotalCostofGoods(): Code[20]
    begin
        exit('5023');
    end;

    internal procedure TotalCostofGoodsName(): Text[100]
    begin
        exit(TotalCostofGoodsTok);
    end;


    internal procedure CostofResourcesandServices(): Code[20]
    begin
        exit('5900');
    end;

    internal procedure CostofResourcesandServicesName(): Text[100]
    begin
        exit(CostofResourcesandServicesTok);
    end;


    internal procedure CostofLabor(): Code[20]
    begin
        exit('5901');
    end;

    internal procedure CostofLaborName(): Text[100]
    begin
        exit(CostofLaborTok);
    end;


    internal procedure CostofLaborProjects(): Code[20]
    begin
        exit('5902');
    end;

    internal procedure CostofLaborProjectsName(): Text[100]
    begin
        exit(CostofLaborProjectsTok);
    end;


    internal procedure CostofLaborWarranty_Contract(): Code[20]
    begin
        exit('5903');
    end;

    internal procedure CostofLaborWarranty_ContractName(): Text[100]
    begin
        exit(CostofLaborWarranty_ContractTok);
    end;


    internal procedure TotalCostofResources(): Code[20]
    begin
        exit('5905');
    end;

    internal procedure TotalCostofResourcesName(): Text[100]
    begin
        exit(TotalCostofResourcesTok);
    end;


    internal procedure CostsofJobs(): Code[20]
    begin
        exit('5040');
    end;

    internal procedure CostsofJobsName(): Text[100]
    begin
        exit(CostsofJobsTok);
    end;


    internal procedure JobCosts(): Code[20]
    begin
        exit('5041');
    end;

    internal procedure JobCostsName(): Text[100]
    begin
        exit(JobCostsTok);
    end;


    internal procedure JobCostsApplied(): Code[20]
    begin
        exit('5042');
    end;

    internal procedure JobCostsAppliedName(): Text[100]
    begin
        exit(JobCostsAppliedTok);
    end;


    internal procedure TotalCostsofJobs(): Code[20]
    begin
        exit('5043');
    end;

    internal procedure TotalCostsofJobsName(): Text[100]
    begin
        exit(TotalCostsofJobsTok);
    end;


    internal procedure Subcontractedwork(): Code[20]
    begin
        exit('5904');
    end;

    internal procedure SubcontractedworkName(): Text[100]
    begin
        exit(SubcontractedworkTok);
    end;


    internal procedure ManufVariances(): Code[20]
    begin
        exit('5030');
    end;

    internal procedure ManufVariancesName(): Text[100]
    begin
        exit(ManufVariancesTok);
    end;


    internal procedure PurchaseVarianceCap(): Code[20]
    begin
        exit('5031');
    end;

    internal procedure PurchaseVarianceCapName(): Text[100]
    begin
        exit(PurchaseVarianceCapTok);
    end;


    internal procedure MaterialVariance(): Code[20]
    begin
        exit('5032');
    end;

    internal procedure MaterialVarianceName(): Text[100]
    begin
        exit(MaterialVarianceTok);
    end;


    internal procedure CapacityVariance(): Code[20]
    begin
        exit('5033');
    end;

    internal procedure CapacityVarianceName(): Text[100]
    begin
        exit(CapacityVarianceTok);
    end;


    internal procedure SubcontractedVariance(): Code[20]
    begin
        exit('5034');
    end;

    internal procedure SubcontractedVarianceName(): Text[100]
    begin
        exit(SubcontractedVarianceTok);
    end;


    internal procedure CapOverheadVariance(): Code[20]
    begin
        exit('5035');
    end;

    internal procedure CapOverheadVarianceName(): Text[100]
    begin
        exit(CapOverheadVarianceTok);
    end;


    internal procedure MfgOverheadVariance(): Code[20]
    begin
        exit('5036');
    end;

    internal procedure MfgOverheadVarianceName(): Text[100]
    begin
        exit(MfgOverheadVarianceTok);
    end;


    internal procedure TotalManufVariances(): Code[20]
    begin
        exit('5038');
    end;

    internal procedure TotalManufVariancesName(): Text[100]
    begin
        exit(TotalManufVariancesTok);
    end;


    internal procedure CostofVariances(): Code[20]
    begin
        exit('5039');
    end;

    internal procedure CostofVariancesName(): Text[100]
    begin
        exit(CostofVariancesTok);
    end;


    internal procedure TOTALCOSTOFGOODSSOLD(): Code[20]
    begin
        exit('5999');
    end;

    internal procedure TOTALCOSTOFGOODSSOLDName(): Text[100]
    begin
        exit(TOTALCOSTOFGOODSSOLDTok);
    end;


    internal procedure EXPENSES(): Code[20]
    begin
        exit('6');
    end;

    internal procedure EXPENSESName(): Text[100]
    begin
        exit(EXPENSESTok);
    end;


    internal procedure RentalFacilities(): Code[20]
    begin
        exit('6309');
    end;

    internal procedure RentalFacilitiesName(): Text[100]
    begin
        exit(RentalFacilitiesTok);
    end;


    internal procedure Rent_Leases(): Code[20]
    begin
        exit('6310');
    end;

    internal procedure Rent_LeasesName(): Text[100]
    begin
        exit(Rent_LeasesTok);
    end;


    internal procedure ElectricityforRental(): Code[20]
    begin
        exit('6325');
    end;

    internal procedure ElectricityforRentalName(): Text[100]
    begin
        exit(ElectricityforRentalTok);
    end;


    internal procedure HeatingforRental(): Code[20]
    begin
        exit('6320');
    end;

    internal procedure HeatingforRentalName(): Text[100]
    begin
        exit(HeatingforRentalTok);
    end;


    internal procedure WaterandSewerageforRental(): Code[20]
    begin
        exit('6326');
    end;

    internal procedure WaterandSewerageforRentalName(): Text[100]
    begin
        exit(WaterandSewerageforRentalTok);
    end;


    internal procedure CleaningandWasteforRental(): Code[20]
    begin
        exit('6330');
    end;

    internal procedure CleaningandWasteforRentalName(): Text[100]
    begin
        exit(CleaningandWasteforRentalTok);
    end;


    internal procedure RepairsandMaintenanceforRental(): Code[20]
    begin
        exit('6335');
    end;

    internal procedure RepairsandMaintenanceforRentalName(): Text[100]
    begin
        exit(RepairsandMaintenanceforRentalTok);
    end;


    internal procedure InsurancesRental(): Code[20]
    begin
        exit('6340');
    end;

    internal procedure InsurancesRentalName(): Text[100]
    begin
        exit(InsurancesRentalTok);
    end;


    internal procedure OtherRentalExpenses(): Code[20]
    begin
        exit('6345');
    end;

    internal procedure OtherRentalExpensesName(): Text[100]
    begin
        exit(OtherRentalExpensesTok);
    end;


    internal procedure TotalRentalFacilities(): Code[20]
    begin
        exit('6399');
    end;

    internal procedure TotalRentalFacilitiesName(): Text[100]
    begin
        exit(TotalRentalFacilitiesTok);
    end;


    internal procedure Hireofmachinery(): Code[20]
    begin
        exit('6836');
    end;

    internal procedure HireofmachineryName(): Text[100]
    begin
        exit(HireofmachineryTok);
    end;


    internal procedure Hireofcomputers(): Code[20]
    begin
        exit('6840');
    end;

    internal procedure HireofcomputersName(): Text[100]
    begin
        exit(HireofcomputersTok);
    end;


    internal procedure Hireofotherfixedassets(): Code[20]
    begin
        exit('6845');
    end;

    internal procedure HireofotherfixedassetsName(): Text[100]
    begin
        exit(HireofotherfixedassetsTok);
    end;


    internal procedure PassengerCarCosts(): Code[20]
    begin
        exit('6500');
    end;

    internal procedure PassengerCarCostsName(): Text[100]
    begin
        exit(PassengerCarCostsTok);
    end;


    internal procedure TruckCosts(): Code[20]
    begin
        exit('6520');
    end;

    internal procedure TruckCostsName(): Text[100]
    begin
        exit(TruckCostsTok);
    end;


    internal procedure Othervehicleexpenses(): Code[20]
    begin
        exit('6595');
    end;

    internal procedure OthervehicleexpensesName(): Text[100]
    begin
        exit(OthervehicleexpensesTok);
    end;


    internal procedure Freightfeesforgoods(): Code[20]
    begin
        exit('6740');
    end;

    internal procedure FreightfeesforgoodsName(): Text[100]
    begin
        exit(FreightfeesforgoodsTok);
    end;


    internal procedure Customsandforwarding(): Code[20]
    begin
        exit('6760');
    end;

    internal procedure CustomsandforwardingName(): Text[100]
    begin
        exit(CustomsandforwardingTok);
    end;


    internal procedure Freightfeesprojects(): Code[20]
    begin
        exit('6780');
    end;

    internal procedure FreightfeesprojectsName(): Text[100]
    begin
        exit(FreightfeesprojectsTok);
    end;


    internal procedure TravelExpenses(): Code[20]
    begin
        exit('6649');
    end;

    internal procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;


    internal procedure Tickets(): Code[20]
    begin
        exit('6663');
    end;

    internal procedure TicketsName(): Text[100]
    begin
        exit(TicketsTok);
    end;


    internal procedure Rentalvehicles(): Code[20]
    begin
        exit('6668');
    end;

    internal procedure RentalvehiclesName(): Text[100]
    begin
        exit(RentalvehiclesTok);
    end;


    internal procedure Boardandlodging(): Code[20]
    begin
        exit('6660');
    end;

    internal procedure BoardandlodgingName(): Text[100]
    begin
        exit(BoardandlodgingTok);
    end;


    internal procedure Othertravelexpenses(): Code[20]
    begin
        exit('6650');
    end;

    internal procedure OthertravelexpensesName(): Text[100]
    begin
        exit(OthertravelexpensesTok);
    end;


    internal procedure TotalTravelExpenses(): Code[20]
    begin
        exit('6669');
    end;

    internal procedure TotalTravelExpensesName(): Text[100]
    begin
        exit(TotalTravelExpensesTok);
    end;


    internal procedure AdvertisementDevelopment(): Code[20]
    begin
        exit('6600');
    end;

    internal procedure AdvertisementDevelopmentName(): Text[100]
    begin
        exit(AdvertisementDevelopmentTok);
    end;


    internal procedure OutdoorandTransportationAds(): Code[20]
    begin
        exit('6601');
    end;

    internal procedure OutdoorandTransportationAdsName(): Text[100]
    begin
        exit(OutdoorandTransportationAdsTok);
    end;


    internal procedure Admatteranddirectmailings(): Code[20]
    begin
        exit('6602');
    end;

    internal procedure AdmatteranddirectmailingsName(): Text[100]
    begin
        exit(AdmatteranddirectmailingsTok);
    end;


    internal procedure Conference_ExhibitionSponsorship(): Code[20]
    begin
        exit('6603');
    end;

    internal procedure Conference_ExhibitionSponsorshipName(): Text[100]
    begin
        exit(Conference_ExhibitionSponsorshipTok);
    end;


    internal procedure Samplescontestsgifts(): Code[20]
    begin
        exit('6605');
    end;

    internal procedure SamplescontestsgiftsName(): Text[100]
    begin
        exit(SamplescontestsgiftsTok);
    end;


    internal procedure FilmTVradiointernetads(): Code[20]
    begin
        exit('6604');
    end;

    internal procedure FilmTVradiointernetadsName(): Text[100]
    begin
        exit(FilmTVradiointernetadsTok);
    end;


    internal procedure CreditCardCharges(): Code[20]
    begin
        exit('6690');
    end;

    internal procedure CreditCardChargesName(): Text[100]
    begin
        exit(CreditCardChargesTok);
    end;


    internal procedure BusinessEntertainingdeductible(): Code[20]
    begin
        exit('6640');
    end;

    internal procedure BusinessEntertainingdeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingdeductibleTok);
    end;


    internal procedure BusinessEntertainingnondeductible(): Code[20]
    begin
        exit('6644');
    end;

    internal procedure BusinessEntertainingnondeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingnondeductibleTok);
    end;


    internal procedure OfficeSupplies(): Code[20]
    begin
        exit('6815');
    end;

    internal procedure OfficeSuppliesName(): Text[100]
    begin
        exit(OfficeSuppliesTok);
    end;


    internal procedure PhoneServices(): Code[20]
    begin
        exit('6805');
    end;

    internal procedure PhoneServicesName(): Text[100]
    begin
        exit(PhoneServicesTok);
    end;


    internal procedure Dataservices(): Code[20]
    begin
        exit('6810');
    end;

    internal procedure DataservicesName(): Text[100]
    begin
        exit(DataservicesTok);
    end;


    internal procedure Postalfees(): Code[20]
    begin
        exit('6800');
    end;

    internal procedure PostalfeesName(): Text[100]
    begin
        exit(PostalfeesTok);
    end;


    internal procedure Consumable_Expensiblehardware(): Code[20]
    begin
        exit('6850');
    end;

    internal procedure Consumable_ExpensiblehardwareName(): Text[100]
    begin
        exit(Consumable_ExpensiblehardwareTok);
    end;


    internal procedure Softwareandsubscriptionfees(): Code[20]
    begin
        exit('6837');
    end;

    internal procedure SoftwareandsubscriptionfeesName(): Text[100]
    begin
        exit(SoftwareandsubscriptionfeesTok);
    end;


    internal procedure CorporateInsurance(): Code[20]
    begin
        exit('6400');
    end;

    internal procedure CorporateInsuranceName(): Text[100]
    begin
        exit(CorporateInsuranceTok);
    end;


    internal procedure BadDebtLosses(): Code[20]
    begin
        exit('6930');
    end;

    internal procedure BadDebtLossesName(): Text[100]
    begin
        exit(BadDebtLossesTok);
    end;


    internal procedure Annual_interrimReports(): Code[20]
    begin
        exit('6827');
    end;

    internal procedure Annual_interrimReportsName(): Text[100]
    begin
        exit(Annual_interrimReportsTok);
    end;


    internal procedure PayableInvoiceRounding(): Code[20]
    begin
        exit('7400');
    end;

    internal procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;


    internal procedure AccountingServices(): Code[20]
    begin
        exit('6830');
    end;

    internal procedure AccountingServicesName(): Text[100]
    begin
        exit(AccountingServicesTok);
    end;


    internal procedure LegalFeesandAttorneyServices(): Code[20]
    begin
        exit('6825');
    end;

    internal procedure LegalFeesandAttorneyServicesName(): Text[100]
    begin
        exit(LegalFeesandAttorneyServicesTok);
    end;


    internal procedure OtherExternalServices(): Code[20]
    begin
        exit('6303');
    end;

    internal procedure OtherExternalServicesName(): Text[100]
    begin
        exit(OtherExternalServicesTok);
    end;


    internal procedure Miscexternalexpenses(): Code[20]
    begin
        exit('6300');
    end;

    internal procedure MiscexternalexpensesName(): Text[100]
    begin
        exit(MiscexternalexpensesTok);
    end;


    internal procedure PurchaseDiscounts(): Code[20]
    begin
        exit('7130');
    end;

    internal procedure PurchaseDiscountsName(): Text[100]
    begin
        exit(PurchaseDiscountsTok);
    end;


    internal procedure Personnel(): Code[20]
    begin
        exit('6001');
    end;

    internal procedure PersonnelName(): Text[100]
    begin
        exit(PersonnelTok);
    end;


    internal procedure Salaries(): Code[20]
    begin
        exit('6020');
    end;

    internal procedure SalariesName(): Text[100]
    begin
        exit(SalariesTok);
    end;


    internal procedure HourlyWages(): Code[20]
    begin
        exit('6010');
    end;

    internal procedure HourlyWagesName(): Text[100]
    begin
        exit(HourlyWagesTok);
    end;


    internal procedure OvertimeWages(): Code[20]
    begin
        exit('6011');
    end;

    internal procedure OvertimeWagesName(): Text[100]
    begin
        exit(OvertimeWagesTok);
    end;


    internal procedure Bonuses(): Code[20]
    begin
        exit('6029');
    end;

    internal procedure BonusesName(): Text[100]
    begin
        exit(BonusesTok);
    end;


    internal procedure CommissionsPaid(): Code[20]
    begin
        exit('6012');
    end;

    internal procedure CommissionsPaidName(): Text[100]
    begin
        exit(CommissionsPaidTok);
    end;


    internal procedure Pensionfeesandrecurringcosts(): Code[20]
    begin
        exit('6150');
    end;

    internal procedure PensionfeesandrecurringcostsName(): Text[100]
    begin
        exit(PensionfeesandrecurringcostsTok);
    end;


    internal procedure EmployerContributions(): Code[20]
    begin
        exit('6100');
    end;

    internal procedure EmployerContributionsName(): Text[100]
    begin
        exit(EmployerContributionsTok);
    end;


    internal procedure HealthInsurance(): Code[20]
    begin
        exit('6160');
    end;

    internal procedure HealthInsuranceName(): Text[100]
    begin
        exit(HealthInsuranceTok);
    end;


    internal procedure TotalPersonnel(): Code[20]
    begin
        exit('6199');
    end;

    internal procedure TotalPersonnelName(): Text[100]
    begin
        exit(TotalPersonnelTok);
    end;


    internal procedure DepreciationLandandProperty(): Code[20]
    begin
        exit('6221');
    end;

    internal procedure DepreciationLandandPropertyName(): Text[100]
    begin
        exit(DepreciationLandandPropertyTok);
    end;


    internal procedure DepreciationFixedAssets(): Code[20]
    begin
        exit('6220');
    end;

    internal procedure DepreciationFixedAssetsName(): Text[100]
    begin
        exit(DepreciationFixedAssetsTok);
    end;


    internal procedure CurrencyLosses(): Code[20]
    begin
        exit('6880');
    end;

    internal procedure CurrencyLossesName(): Text[100]
    begin
        exit(CurrencyLossesTok);
    end;


    internal procedure TOTALEXPENSES(): Code[20]
    begin
        exit('7999');
    end;

    internal procedure TOTALEXPENSESName(): Text[100]
    begin
        exit(TOTALEXPENSESTok);
    end;


    internal procedure NETINCOME(): Code[20]
    begin
        exit('8999');
    end;

    internal procedure NETINCOMEName(): Text[100]
    begin
        exit(NETINCOMETok);
    end;
}
