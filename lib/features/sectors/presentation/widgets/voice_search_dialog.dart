import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/voice_command_parser.dart';
import '../../../../core/services/voice_search_service.dart';

class VoiceSearchDialog extends StatefulWidget {
  final String? currentSectorSrc;
  final String? currentSectorDst;
  final void Function(VoiceSearchResult result)? onResultApplied;

  const VoiceSearchDialog({
    super.key,
    this.currentSectorSrc,
    this.currentSectorDst,
    this.onResultApplied,
  });

  static Future<void> show({
    required BuildContext context,
    String? currentSectorSrc,
    String? currentSectorDst,
    void Function(VoiceSearchResult result)? onResultApplied,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => VoiceSearchDialog(
        currentSectorSrc: currentSectorSrc,
        currentSectorDst: currentSectorDst,
        onResultApplied: onResultApplied,
      ),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final TextEditingController _textController = TextEditingController();
  final VoiceSearchService _voiceService = VoiceSearchService.instance;

  bool _isListening = false;
  String? _errorMessage;
  VoiceSearchResult? _currentResult;
  Timer? _autoNavigateTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _pulseController.forward();
        }
      }
    });

    _startListening();
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _pulseController.dispose();
    _textController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  void _startListening() {
    _autoNavigateTimer?.cancel();
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _currentResult = null;
      _countdownSeconds = 0;
      _textController.clear();
    });

    _pulseController.forward();

    _voiceService.startListening(
      onResult: (transcript, isFinal) {
        if (!mounted) return;
        setState(() {
          _textController.text = transcript;
          _currentResult = VoiceCommandParser.parse(transcript);
        });

        if (isFinal) {
          _onSpeechFinalized();
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _errorMessage = err;
        });
        _pulseController.stop();
        _pulseController.reset();
      },
      onEnd: () {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      },
    );
  }

  void _stopListening() {
    _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onSpeechFinalized() {
    _stopListening();
    final res = _currentResult;
    if (res == null) return;

    // Check if we have enough to navigate or apply
    final canApplyDirectly = res.hasSector ||
        (widget.currentSectorSrc != null && widget.currentSectorDst != null && res.hasDate);

    if (canApplyDirectly) {
      // Start auto-navigation countdown of 2 seconds
      setState(() {
        _countdownSeconds = 2;
      });
      _autoNavigateTimer?.cancel();
      _autoNavigateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_countdownSeconds <= 1) {
          timer.cancel();
          _applyResult();
        } else {
          setState(() {
            _countdownSeconds--;
          });
        }
      });
    }
  }

  void _applyResult() {
    _autoNavigateTimer?.cancel();
    final res = _currentResult;
    if (res == null) return;

    if (widget.onResultApplied != null) {
      widget.onResultApplied!(res);
      Navigator.of(context).pop();
      return;
    }

    // Default sector navigation
    String? targetSrc = res.src ?? widget.currentSectorSrc;
    String? targetDst = res.dst ?? widget.currentSectorDst;

    if (targetSrc != null && targetDst != null) {
      Navigator.of(context).pop();
      final dateParam = res.date != null
          ? '?date=${res.date!.year}-${res.date!.month.toString().padLeft(2, '0')}-${res.date!.day.toString().padLeft(2, '0')}'
          : '';
      context.go('/sector/$targetSrc/$targetDst$dateParam');
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final res = _currentResult;
    final isInsideSector = widget.currentSectorSrc != null && widget.currentSectorDst != null;

    final effectiveSrc = res?.src ?? (isInsideSector ? widget.currentSectorSrc : null);
    final effectiveDst = res?.dst ?? (isInsideSector ? widget.currentSectorDst : null);
    final hasEffectiveSector = effectiveSrc != null && effectiveDst != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Voice Sector Search',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Animated Pulsing Mic
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening) ...[
                            Container(
                              width: 80 * _pulseAnimation.value,
                              height: 80 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue.withValues(alpha: 0.18 / _pulseAnimation.value),
                              ),
                            ),
                            Container(
                              width: 66 * _pulseAnimation.value,
                              height: 66 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue.withValues(alpha: 0.28 / _pulseAnimation.value),
                              ),
                            ),
                          ],
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isListening
                                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                    : [AppColors.primaryBlue, const Color(0xFF1E40AF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : AppColors.primaryBlue)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Status indicator
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isListening) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Listening... Speak now',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ] else ...[
                      Text(
                        _errorMessage != null
                            ? 'Error: $_errorMessage'
                            : (_textController.text.isNotEmpty
                                ? 'Tap mic to speak again'
                                : 'Tap mic to start speaking'),
                        style: TextStyle(
                          color: _errorMessage != null ? AppColors.errorRed : AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recognized transcript box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What you said:',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: "Say 'Calicut Dubai October 21'...",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _currentResult = VoiceCommandParser.parse(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Parsed Detection Badges
              if (res != null && (hasEffectiveSector || res.hasDate)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Detected Information:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          if (_countdownSeconds > 0) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Jumping in ${_countdownSeconds}s...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (hasEffectiveSector)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flight_takeoff_rounded, size: 14, color: AppColors.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${res.srcName ?? effectiveSrc} ($effectiveSrc) ➔ ${res.dstName ?? effectiveDst} ($effectiveDst)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (res.hasDate)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(res.date!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Suggestion Hints
              if (res == null || (!hasEffectiveSector && !res.hasDate)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Examples to try:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• "Calicut Dubai October 21"\n• "Kozhikode to Sharjah tomorrow"\n• "Cochin to Jeddah 25 Oct"\n• "Mangalore Abu Dhabi"',
                        style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _autoNavigateTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasEffectiveSector || (isInsideSector && res?.hasDate == true)
                          ? AppColors.primaryBlue
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (hasEffectiveSector || (isInsideSector && res?.hasDate == true))
                        ? _applyResult
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      isInsideSector && !res!.hasSector && res.hasDate
                          ? 'Filter Date'
                          : 'Go to Sector',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
