Shader "Unlit/outline"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineWidth("Outline Width", Range(1, 10)) = 1
		_OutlineSoftness("Outline Softness", Range(1, 10)) = 4

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100
		Fog{ Mode Off }
		Cull Off
		ZWrite Off
		Lighting Off
		ColorMask[_ColorMask]

		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			#include "UnityCG.cginc"

			uniform float4	_OutlineColor;
			uniform float	_OutlineWidth;
			uniform int	_OutlineSoftness;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform half4 _MainTex_TexelSize;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.uv1, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.uv2, _MainTex);
				o.color = v.color;

				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				float4 outlinecolor = _OutlineColor; 

				float2 uv = i.uv;
				float2 uv1 = i.uv1;
				float2 uv2 = i.uv2;

				float4 ot = float4(0,0,0,0);
				float x = 0.0;
				float y = 0.0;

				float4 color = i.color;
				float lx = uv1.x;
				float rx = uv2.x;
				float dy = uv1.y;
				float ty = uv2.y;

				float radius = _OutlineWidth / 15.0;

				for (int i = 1; i < _OutlineSoftness + 1; i++)
				{
					x = i * radius; y = i * radius;

					uv1 = uv + _MainTex_TexelSize.xy * half2(x, 0);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(x, y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(0, y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(-x, y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(-x, 0);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(-x, -y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(0, -y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
					uv1 = uv + _MainTex_TexelSize.xy * half2(x, -y);
					ot += tex2D(_MainTex, float2(clamp(uv1.x, lx, rx), clamp(uv1.y, dy, ty)));
				}

				float a = step(lx, uv.x) * step(uv.x, rx) * step(dy, uv.y) * step(uv.y, ty);
				// float b = (1 - step(ot.a, 0)) * (step(col.a, 1) + 1 - a);

				outlinecolor.a = outlinecolor.a * ot.a;
				color.a *= col.a;
				color = color * a;
				outlinecolor = lerp(outlinecolor, color, col.a) + color * color.a;

				return outlinecolor;// lerp(color, outlinecolor, b);
			}
			ENDCG
		}
	}
}
