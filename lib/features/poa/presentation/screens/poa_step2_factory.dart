import 'package:flutter/material.dart';
import '../../data/models/poa_models.dart';
import 'poa_step2_nsw_screen.dart';
import 'poa_step2_qld_screen.dart';
import 'poa_step2_vic_screen.dart';
import 'poa_step2_sa_screen.dart';
import 'poa_step2_wa_screen.dart';
import 'poa_step2_tas_screen.dart';
import 'poa_step2_nt_screen.dart';
import 'poa_step2_act_screen.dart';

/// Factory that returns the correct Step 2 screen based on user's state.
class PoaStep2Factory {
  static Widget forState(PoaFlowData flowData) {
    final state = flowData.state?.toLowerCase();
    print('[PoaStep2Factory.forState] flowData.state: "${flowData.state}"');
    print('[PoaStep2Factory.forState] Lowercased: "$state"');

    switch (state) {
      case 'queensland':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Qld');
        return PoaStep2Qld(flowData: flowData);
      case 'victoria':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Vic');
        return PoaStep2Vic(flowData: flowData);
      case 'south_australia':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Sa');
        return PoaStep2Sa(flowData: flowData);
      case 'western_australia':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Wa');
        return PoaStep2Wa(flowData: flowData);
      case 'tasmania':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Tas');
        return PoaStep2Tas(flowData: flowData);
      case 'northern_territory':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Nt');
        return PoaStep2Nt(flowData: flowData);
      case 'act':
        print('[PoaStep2Factory.forState] Routing to PoaStep2Act');
        return PoaStep2Act(flowData: flowData);
      default:
        print('[PoaStep2Factory.forState] Routing to PoaStep2Nsw (default)');
        return PoaStep2Nsw(flowData: flowData);
    }
  }
}
