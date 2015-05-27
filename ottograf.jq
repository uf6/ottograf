. as $all
##
#
# Find @relation hints in the @context
#
#
| .["@context"] as $context 
  | $context 
  | to_entries 
  | map(select(.value | .["@relation"]? == true)) 
  | [ .[].key ] as $links 
##
#
# Build root object by removing @relation and @context keys
#
#
| $all 
  | del(.["@context"])
  | to_entries 
  | map(select( [.key] as $keys 
              | $links 
              | contains($keys) 
              | not )) 
  | from_entries 
  | . as $root
  # | reduce ( $opt_transform | fromjson )[] as $transform ( $root
  #                                                        ; . 
  #                                                        | with_entries(.key |= ( if . == ( $transform | .input | tostring ) 
  #                                                                                 then ( $transform | .output  | tostring ) 
  #                                                                                 else . end )) ) |  . as $root
#  | with_entries(.key |= ( if . == "@id" then "id" else . end )) | . as $root 
##
#
# Recursively traverse the input and recognise unique nodes.
#
#
| $all
  | del(.["@context"]) 
  | [ .. 
    | objects
    | to_entries
    | map(select( [.key] as $keys
                | $links 
                | contains($keys)))
    | reduce .[] as $item ( []
                          ; . + ( [ $item.value[] 
                                  | {"type": $item.key } + . 
                                  ] ) )   
    ] | reduce .[] as $item ( [] 
                            ; . + $item )
      | unique_by(.["@id"]) | . as $nodes
| $nodes 
  | [ .[]
    | to_entries 
    | map(select( [.key] as $keys 
                | $links 
                | contains($keys) 
                | not )) 
    | from_entries    
#    | with_entries(.key |= ( if . == "@id" then "id" else . end ))
    ] as $nodes 
# Add root object to the nodes array.
| ( [ $root ] + $nodes ) as $nodes
##
#
# Build the edges array.
#
#
| [ $all
  | del(.["@context"])
  | ..
  | .["@id"]? as $id
  | $links[]
  | . as $link
  | $all
  | ..
  | objects
  | select(.["@id"]? == $id)
  | to_entries 
  | map(select( [.key] as $keys 
              | [ $link ] 
              | contains($keys)))
  | [ .[].value[]
    | { ($opt_source)   : ( if ($opt_index == "numeric") then ( [ $nodes[] | .["@id"] ]| index($id) ) else $id end )
      , type : $link
      , ($opt_target)   : ( if ($opt_index == "numeric") then ( .["@id"] as $target | [ $nodes[] | .["@id"] ]| index($target) ) else (.["@id"]?) end)
      } ]
  ] | reduce .[] as $item ( [] 
                          ; . + $item )
    | [ .[] | select( (.["\($opt_target)"]? | length) !=0 ) ] 
    | . as $edges 
##
#
# Transform input keys into specified output keys.
#
#
| $nodes
| [ .[] as $node
  | reduce ( $opt_transform | fromjson )[] as $transform_nodes ( $node
                                                               ; with_entries(.key |= ( if . == ( $transform_nodes | .input | tostring ) 
                                                                                        then ( $transform_nodes | .output  | tostring ) 
                                                                                        else . end )) ) | . ] |  . as $nodes
| $edges
| [ .[] as $edge
  | reduce ( $opt_transform | fromjson )[] as $transform_nodes ( $edge
                                                               ; with_entries(.key |= ( if . == ( $transform_nodes | .input | tostring ) 
                                                                                        then ( $transform_nodes | .output  | tostring ) 
                                                                                        else . end )) ) | . ] |  . as $edges
##
#
# Output the graph (merging prefix if needed).
#
# 
| ($opt_graph_prefix | fromjson) 
  * { ($opt_nodes): $nodes
    , ($opt_edges): $edges
    } 