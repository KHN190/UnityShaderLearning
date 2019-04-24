Shader "Custom/ToonShader" {
    Properties {
        // Main Tint
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // Main Texture
        _MainTex ("Main Tex", 2D) = "white" {}
        // Tint Texture For Diffuse
        _Ramp ("Ramp Texture", 2D) = "white" {}
        // Outline Strength
        _Outline ("Outline", Range(0, 1)) = 0.1
        // Outline Color
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        // Specular Color
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // Specular Threshold
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
    }
    
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass {
            NAME "OUTLINE"
            
            // Render Backward Only
            Cull Front
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            float _Outline;
            fixed4 _OutlineColor;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            }; 
            
            struct v2f {
                float4 pos : SV_POSITION;
            };
            
            v2f vert (a2v v) {
                v2f o;
                
                // Transform verteces to view space
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                // Transform normal to view space but inverse
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                
                // pos = pos + normal * outline
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline;
                
                // Transform to projection/clip space
                // Finish transformation
                o.pos = mul(UNITY_MATRIX_P, pos);
                
                return o;
            }
            
            float4 frag(v2f i) : SV_Target {
                return float4(_OutlineColor.rgb, 1);               
            }
            
            ENDCG
        }
        
        Pass {
            Tags { "LightMode"="ForwardBase" }
            
            // Render Forward Only
            Cull Back

            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fwdbase
        
            // Helper Functions
            #include "UnityCG.cginc"
            // Light and Shadowing for Surface Shaders
            #include "Lighting.cginc"
            // Standard Ligt for Surface Shaders
            #include "AutoLight.cginc"
            // Globle Variables
            #include "UnityShaderVariables.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            }; 

            struct v2f {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert (a2v v) {
                v2f o;
                
                // Transform verteces to projection space
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // Vertex program uses the TRANSFORM_TEX macro from UnityCG.cginc 
                // to make sure texture scale and offset is applied correctly
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
                
                // mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); ??
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // unity_ObjectToWorld:
                //   Transforms the mesh vertices from their local mesh space to Unity world space
                //   Same as UNITY_MATRIX_M, thus the Model Transform
                // Thus, the next line transforms veteces to world space.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // Compute shadow data
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            float4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
                
                //fixed4 c = tex2D (_MainTex, i.uv);
                fixed3 albedo = tex2D (_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // Light Decay (attenuation)
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // Half Lambert
                fixed diff =  dot(worldNormal, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                
                // Light * Albedo (Tint) * Texture
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;
                
                fixed spec = dot(worldNormal, worldHalfDir);
                fixed w = fwidth(spec) * 2.0;
                
                // smoothstep: hermite interpolation
                // lerp: linear interpolation
                // step(a, x): 0 if x < a else 1
                
                // Set threshold for specular area
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                
                return fixed4(ambient + diffuse + specular, 1.0);
            }
        
            ENDCG
        }
    }
    FallBack "Diffuse"
}