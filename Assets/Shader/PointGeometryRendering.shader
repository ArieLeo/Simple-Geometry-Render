﻿Shader "Custom/PointGeometryRendering"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque"  "LightMode" = "ForwardBase" }

		Cull Back
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Size;
			
			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = mul(unity_ObjectToWorld,v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = mul(v.normal, unity_WorldToObject);
				return o;
			}

			[maxvertexcount(34)]
			void geom(triangle v2g IN[3], inout PointStream<g2f> triStream )
			{
				float4 v0 = IN[0].vertex;
				float4 v1 = IN[1].vertex;
				float4 v2 = IN[2].vertex;

				float3 n0 = IN[0].normal;
				float3 n1 = IN[1].normal;
				float3 n2 = IN[2].normal;

				float2 uvOriginal = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
				float3 normal = normalize((n0 + n1 + n2) / 3);
				float4 center = (v0 + v1 + v2) / 3;

				float4x4 vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);

				g2f pIn;

				pIn.vertex = mul(vp, v0);
				pIn.uv = IN[0].uv;
				pIn.normal = normal;
				triStream.Append(pIn);
				
				pIn.vertex = mul(vp, v1);
				pIn.uv = IN[1].uv;
				pIn.normal = normal;
				triStream.Append(pIn);

				pIn.vertex = mul(vp, v2);
				pIn.uv = IN[2].uv;
				pIn.normal = normal;
				triStream.Append(pIn);

				pIn.vertex = mul(vp, center);
				pIn.uv = uvOriginal;
				pIn.normal = normal;
				triStream.Append(pIn);

				float nPoints = 5;
				float nPointDistance = 1 / nPoints;
				for (int i = 0; i < nPoints; i++) {
					pIn.vertex = mul(vp, center + (v0 - center)*nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);

					pIn.vertex = mul(vp, center + (v1 - center)*nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);

					pIn.vertex = mul(vp, center + (v2 - center)*nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);

					pIn.vertex = mul(vp, center + ((v0 - center)+ (v1 - center)) / 2 *nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);

					pIn.vertex = mul(vp, center + ((v1 - center) + (v2 - center)) / 2 *nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);

					pIn.vertex = mul(vp, center + ((v2 - center) + (v0 - center)) / 2 *nPointDistance*i);
					pIn.uv = uvOriginal;
					pIn.normal = normal;
					triStream.Append(pIn);
				}

				triStream.RestartStrip();
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				float ldotn = max(dot(_WorldSpaceLightPos0, i.normal),.5);
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb *= ldotn;
				return col;
			}
			ENDCG
		}
	}
}
