// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SpecularShader"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,0,1)
        _Specular ("Specular", Color) = (1,1,0,1) // highligt color
        _Gloss ("Gloss", Range(8.0, 256)) = 20    // highlight area size
    }
    
    CGINCLUDE
    #include "Lighting.cginc" // lib to calc reflection
    
    float4 _Diffuse;
    float4 _Specular;
    float _Gloss;
    
    struct a2v {
        float4 vertex : POSITION;
        float4 normal : NORMAL;
    };
    
    struct v2f {
        float4 pos : SV_POSITION;
        fixed3 color : COLOR;
    };
    
    v2f vert(a2v v) {
        v2f o;
        
        // ambient
        fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
        
        fixed3 worldNormal = normalize(mul(v.normal, (float3x3) unity_WorldToObject));
        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
        
        // diffuse
        fixed4 halfLambert = saturate(dot(worldNormal, worldLightDir)) * 0.7 + 0.3;
        fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;
        
        // specular
        fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
        fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
        
        fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
        
        // combined
        o.pos = UnityObjectToClipPos(v.vertex);
        o.color = ambient + diffuse + specular;
        
        return o;
    }
    
    fixed4 frag(v2f i) : SV_Target {
        return fixed4(i.color, 1.0);
    }
    
    ENDCG
    
    SubShader
    {
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag 
            
            ENDCG
        }
    }
    
    FallBack "Diffuse"
}
