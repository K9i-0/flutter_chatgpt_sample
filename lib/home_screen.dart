import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatgpt_sample/build_context_x.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_screen.g.dart';

@riverpod
class Messages extends _$Messages {
  @override
  List<OpenAIChatCompletionChoiceMessageModel> build() => [
        // システムメッセージでAIの動作を調整
        OpenAIChatCompletionChoiceMessageModel(
          content: '日本語で技術の相談をされます。あなたはエクスパートです。',
          role: 'system',
        ),
      ];
  // UI調整用のダミーメッセージ
//   => [
//         OpenAIChatCompletionChoiceMessageModel(
//           content: 'Flutterとはなんですか？',
//           role: 'user',
//         ),
//         OpenAIChatCompletionChoiceMessageModel(
//           content: '''
// Flutterとは、Googleが開発しているオープンソースのUIフレームワークです。Flutterは、iOSやAndroid、Web、Windows、macOS、Linuxなど、複数のプラットフォームで動作する高品質なネイティブアプリを簡単に作成することができます。

// Flutterの特徴は、高速で美しいUIを簡単に作成できることです。Flutterは、アニメーションやエフェクトなどの複雑なUIをスムーズに動作させることができます。また、Flutterのウィジェットライブラリには、さまざまなデザイン要素が含まれており、カスタマイズ性が高く、デザインに応じたUIを簡単に作成することができます。

// Flutterは、Dartというプログラミング言語で開発されています。Dartは、高い生産性、高速処理、型付け言語としての特徴を持っています。Flutterの開発環境には、Android StudioやVisual Studio Codeなどがあり、また、Flutterのコミュニティも活発で、多くのコンポーネントやプラグインが公開されています。''',
//           role: 'assistant',
//         ),
//       ];

  Future<void> sendMessage(String message) async {
    // メッセージをuserロールでモデル化
    final newUserMessage = OpenAIChatCompletionChoiceMessageModel(
      content: message,
      role: 'user',
    );
    // メッセージを追加
    state = [
      ...state,
      newUserMessage,
    ];
    // ChatGPTに聞く
    final chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-3.5-turbo',
      // これまでのやりとりを含めて送信
      messages: [
        ...state,
        newUserMessage,
      ],
    );
    // 結果を追加
    state = [
      ...state,
      chatCompletion.choices.first.message,
    ];
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final messageController = useTextEditingController(text: 'Flutterとはなんですか？');
    final screenWidth = MediaQuery.of(context).size.width;
    final isWaiting = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatGPT Sample'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // メッセージ一覧
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  // systemロールのメッセージは表示しない
                  if (message.role == 'system') {
                    return const SizedBox();
                  }

                  return Align(
                    key: Key(message.hashCode.toString()),
                    alignment: message.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.8,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: message.role == 'user'
                              ? context.colorScheme.primary
                              : context.colorScheme.secondary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: message.role == 'user'
                                  ? context.colorScheme.onPrimary
                                  : context.colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
              ),
            ),
            // 送信フォーム
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'メッセージを入力',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isWaiting.value)
                      IconButton(
                        onPressed: () async {
                          if (messageController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('メッセージを入力してください'),
                              ),
                            );
                          } else {
                            final sendMessage =
                                ref.read(messagesProvider.notifier).sendMessage(
                                      messageController.text,
                                    );
                            isWaiting.value = true;
                            messageController.clear();
                            await sendMessage;
                            isWaiting.value = false;
                          }
                        },
                        icon: !isWaiting.value
                            ? const Icon(Icons.send)
                            : const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    if (isWaiting.value)
                      const IconButton(
                        onPressed: null,
                        icon: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
