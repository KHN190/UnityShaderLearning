Shader "Custom/ReflectionShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1) // highligt color
        _Gloss ("Gloss", Range(8.0, 256)) = 20    // highlight area size
        
        _ReflectColor ("Reflect Color", Color) = (1,1,1,1)
        _ReflectAmount ("Reflect Amount", Range(0, 1)) = 1
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}
    }
    
    CGINCLUDE
    #include "Lighting.cginc"
    #include "AutoLight.cginc"
            
    fixed4 _Color;
    float4 _Specular;
    float _Gloss;
    
    fixed4 _ReflectColor;
    fixed _ReflectAmount;
    
    samplerCUBE _Cubemap;
    
    struct a2v {
        float4 vertex : POSITION;
        float4 normal : NORMAL;
    };
    
    struct v2f {
        float4 pos : SV_POSITION;
        float3 worldPos : TEXCOORD0;
        fixed3 worldNormal : TEXCOORD1;
        fixed3 worldViewDir : TEXCOORD2;
        fixed3 worldLightDir : TEXCOORD3;
        SHADOW_COORDS(4)
    };
    
    v2f vert(a2v v) {
        v2f o;
        
        o.pos = UnityObjectToClipPos(v.vertex);
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;;
        o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
        o.worldLightDir = UnityWorldSpaceLightDir(o.worldPos);
        
        TRANSFER_SHADOW(o);
        
        return o;
    }
    
    fixed4 frag(v2f i) : SV_Target {
    
        fixed3 worldNormal = normalize(i.worldNormal);
        fixed3 worldLightDir = normalize(i.worldLightDir);   
        fixed3 worldViewDir = normalize(i.worldViewDir);
        
        // ambient
        fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
        
        // diffuse
        fixed4 halfLambert = saturate(dot(worldNormal, worldLightDir)) * 0.7 + 0.3;
        fixed3 diffuse = _LightColor0.rgb * _Color.rgb * halfLambert;
        
        // reflect
        fixed3 worldRefl = normalize(reflect(-worldLightDir, worldNormal));
        fixed3 reflection = texCUBE(_Cubemap, worldRefl).rgb * _ReflectColor.rgb;
        
        // or
        //fixed3 worldViewDir = normalize(i.worldViewDir);
        //fixed3 worldRefl = normalize(reflect(worldViewDir, worldNormal));
        
        // specular
        fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldRefl, worldViewDir)), _Gloss);
        
        UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
        
        // combined
        fixed3 color = ambient + specular + lerp(diffuse, reflection, _ReflectAmount) * atten;
        
        return fixed4(color, 1.0);
    }
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag 

            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
