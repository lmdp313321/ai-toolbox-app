/// 硅基流动推荐模型配置（自用够用版）
/// 注意：模型可用性请在你的硅基控制台确认
class SiliconModels {
  
  /// ========== 文本对话模型（够用就行） ==========
  static const String chatDefault = 'deepseek-ai/DeepSeek-V2.5';
  
  static const Map<String, String> chatModels = {
    'DeepSeek-V2.5': 'deepseek-ai/DeepSeek-V2.5',
    'Qwen2.5-14B': 'Qwen/Qwen2.5-14B-Instruct',
    'GLM-4-9B': 'THUDM/glm-4-9b-chat',
  };
  
  /// ========== 文生图模型（性价比优先） ==========
  /// 推荐：FLUX.1-schnell - 速度快，价格便宜
  static const String imageDefault = 'black-forest-labs/FLUX.1-schnell';
  
  static const Map<String, String> imageModels = {
    'FLUX.1-schnell': 'black-forest-labs/FLUX.1-schnell',  // 推荐：快+便宜
    'SD3-Medium': 'stabilityai/stable-diffusion-3-medium', // 质量更好但贵
    'SDXL-Lightning': 'ByteDance/SDXL-Lightning',          // 超快
  };
  
  /// ========== 语音合成模型（TTS） ==========
  static const String ttsDefault = 'FunAudioLLM/CosyVoice2-0.5B';
  
  static const Map<String, String> ttsModels = {
    'CosyVoice2': 'FunAudioLLM/CosyVoice2-0.5B',
  };
  
  /// ========== 语音识别模型（STT） ==========
  static const String sttDefault = 'iic/SenseVoiceSmall';
  
  static const Map<String, String> sttModels = {
    'SenseVoice': 'iic/SenseVoiceSmall',
  };
  
  /// ========== 向量/嵌入模型（文档RAG用） ==========
  static const String embeddingDefault = 'BAAI/bge-m3';
  
  static const Map<String, String> embeddingModels = {
    'bge-m3': 'BAAI/bge-m3',
  };
}

/// 各功能推荐的默认模型（够用就行）
class DefaultModels {
  static const String chat = 'deepseek-ai/DeepSeek-V2.5';
  static const String image = 'black-forest-labs/FLUX.1-schnell';
  static const String tts = 'FunAudioLLM/CosyVoice2-0.5B';
  static const String stt = 'iic/SenseVoiceSmall';
  static const String embedding = 'BAAI/bge-m3';
}
