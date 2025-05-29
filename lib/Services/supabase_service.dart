
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thread_app/utils/env.dart';

class SupabaseService extends GetxService {

  @override
  void onInit() async{
    await Supabase.initialize(url: Env.superbaseUrl, anonKey:Env.superbaseKey );
    super.onInit();
  }
static final SupabaseClient client = Supabase.instance.client;

}

