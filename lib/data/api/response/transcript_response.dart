import 'package:flutter/material.dart';
import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/data/model/transcript_chunk_line.dart';
import 'package:radiozeit/data/model/transcript_chunk_word.dart';
import 'package:radiozeit/utils/json_map.dart';

// class TranscriptResponse extends ServerResponse {
//   List<TranscriptChunk> chunkList = [];
//
//   TranscriptResponse(super.response);
//
//   @override
//   parse(HttpApiResponse response) {
//     super.parse(response);
//     if(success) {
//       var items = JsonMap.toList(response.data);
//       chunkList = items.map((e) => TranscriptChunk.fromJson(e)).toList();
//     }
//   }
// }

class TranscriptResponse extends ServerResponse {
  List<TranscriptChunkLine> chunkList = [];
  List<TranscriptChunkWord> wordList = [];

  TranscriptResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      var items = JsonMap.toList(response.data);

      for(var e in items) {
        double chunkStartTime = (JsonMap.toDouble(e["chunk_timestamp"]) ?? 0.0) -
            (JsonMap.toDouble(e["ffmpeg_start_time"]) ?? 0.0);
        var tokens = JsonMap.toList(e["tokens"]);
        var words = tokens.map((token) {
          return TranscriptChunk(
            start: chunkStartTime + token["start"],
            to: chunkStartTime + token["stop"],
            content: token["content"],

          );
        }).toList();

        List<TranscriptChunk> wordChunks = [];
        for (var chunk in words) {
          if(wordChunks.isNotEmpty &&  chunk.content.startsWith(" ")) {
            wordList.add(
                TranscriptChunkWord(
                    chunks: wordChunks,
                  isBrakeLine: false
                )
            );
            var last = wordChunks.last.content;
            if(last.contains(".") || last.contains("!") || last.contains("?")) {
              wordList.add(
                  TranscriptChunkWord(
                      chunks: [],
                      isBrakeLine: true
                  )
              );
            }
            wordChunks = [];
          }
          wordChunks.add(chunk);
        }
        if(wordChunks.isNotEmpty) {
          wordList.add(
              TranscriptChunkWord(
                  chunks: wordChunks,
                  isBrakeLine: false
              )
          );
          var last = wordChunks.last.content;
          if(last.contains(".") || last.contains("!") || last.contains("?")) {
            wordList.add(
                TranscriptChunkWord(
                    chunks: [],
                    isBrakeLine: true
                )
            );
          }
        }

        chunkList.add(
            TranscriptChunkLine(
                content: e["content"],
                start: chunkStartTime + e["start"],
                end: chunkStartTime + e["stop"],
                words: words
            )
        );
      }
    }
  }


}