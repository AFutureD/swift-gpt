

based on "Sources/Gemini/vendor/googleapis/google/ai/generativelanguage/v1beta/BUILD.bazel"
```
protoc -I Sources/Gemini/vendor/googleapis \
  --swift_out=Sources/Gemini/Proto \
  Sources/Gemini/vendor/googleapis/google/ai/generativelanguage/v1beta/{cache_service,cached_content,citation,content,discuss_service,file,file_service,generative_service,model,model_service,permission,permission_service,prediction_service,retriever,retriever_service,safety,text_service,tuned_model}.proto Sources/Gemini/vendor/googleapis/google/api/{annotations,client,field_behavior,resource,http,launch_stage}.proto Sources/Gemini/vendor/googleapis/google/longrunning/operations.proto Sources/Gemini/vendor/googleapis/google/rpc/status.proto Sources/Gemini/vendor/googleapis/google/type/{interval,latlng}.proto
```