import os
import requests
import logging
import base64
import json
import urllib.parse  # URL 디코딩을 위해 추가
from typing import Dict, List, Optional
from django.conf import settings

logger = logging.getLogger(__name__)


class CodefAPIService:
    """Codef API를 통해 사용자 카드 정보를 조회하는 서비스 클래스"""
    
    # Codef API 기본 정보
    TOKEN_URL = "https://oauth.codef.io/oauth/token"  # Codef OAuth 토큰 발급 URL
    CODEF_API_URL = "https://api.codef.io"  # Codef API 기본 URL
    CODEF_DEV_API_URL = "https://api.codef.io"  # Demo는 정식 URL(api.codef.io)을 사용합니다.
    
    def __init__(self):
        """Codef API 클라이언트 초기화"""
        self.client_id = os.getenv('CODEF_CLIENT_ID')
        self.client_secret = os.getenv('CODEF_CLIENT_SECRET')
        self.access_token = None
        
        if not self.client_id or not self.client_secret:
            logger.warning("Codef API credentials not configured in environment variables")
    
    def get_access_token(self) -> Optional[str]:
        """
        Codef API 액세스 토큰 발급 (Java 코드 기반)
        
        Returns:
            str: 액세스 토큰 (실패 시 None)
        """
        try:
            # 1. Basic Auth 헤더 생성 (Base64 인코딩: clientId:clientSecret)
            auth_string = f"{self.client_id}:{self.client_secret}"
            auth_bytes = auth_string.encode('utf-8')
            auth_encoded = base64.b64encode(auth_bytes).decode('utf-8')
            
            # 2. 요청 헤더 설정
            headers = {
                "Authorization": f"Basic {auth_encoded}",
                "Content-Type": "application/x-www-form-urlencoded"
            }
            
            # 3. 요청 바디 설정
            params = {
                "grant_type": "client_credentials",
                "scope": "read"
            }
            
            # 4. 토큰 발급 요청
            response = requests.post(
                self.TOKEN_URL,
                data=params,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            
            # 5. 응답 처리
            data = response.json()
            self.access_token = data.get('access_token')
            
            if self.access_token:
                logger.info("Codef API access token obtained successfully")
                return self.access_token
            else:
                logger.error("Access token not found in response")
                return None
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get Codef API access token: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in get_access_token: {str(e)}")
            return None
    
    def fetch_user_cards(self, user_id: str, password: str, connection_id: Optional[str] = None) -> Dict:
        """
        Codef API를 통해 사용자의 카드 정보 조회
        
        Args:
            user_id (str): 사용자 Codef ID
            password (str): 사용자 Codef 비밀번호
            connection_id (str, Optional): 연결 ID (재인증 시 사용)
        
        Returns:
            Dict: API 응답 데이터 {
                "success": bool,
                "data": [
                    {
                        "card_name": str,
                        "company": str,
                        "card_number": str,
                        "annual_fee": int,
                        "annual_fee_overseas": int,
                        "card_image_url": str (optional),
                        ...
                    }
                ],
                "error_message": str (on failure)
            }
        """
        try:
            # 1. 액세스 토큰 확인 (없으면 새로 발급)
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            # 2. 카드 정보 조회 API 호출
            url = f"{self.CODEF_API_URL}/v1/kr/card/info"
            
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "identity": user_id,
                "password": password
            }
            
            # connection_id가 있으면 추가
            if connection_id:
                payload["connection_id"] = connection_id
            
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            
            api_response = response.json()
            
            # API 응답 처리
            if api_response.get('result', {}).get('code') == '00000':
                # 성공
                cards_data = api_response.get('data', [])
                logger.info(f"Successfully fetched {len(cards_data)} cards for user")
                
                return {
                    "success": True,
                    "data": cards_data
                }
            else:
                # 실패
                error_msg = api_response.get('result', {}).get('message', 'Unknown error')
                logger.error(f"Codef API error: {error_msg}")
                
                return {
                    "success": False,
                    "error_message": error_msg
                }
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Codef API request failed: {str(e)}")
            return {
                "success": False,
                "error_message": f"API request failed: {str(e)}"
            }
        except Exception as e:
            logger.error(f"Unexpected error in fetch_user_cards: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }
    
    def parse_card_data(self, codef_card_data: Dict) -> Dict:
        """
        Codef API 응답 데이터를 우리 DB 모델에 맞게 파싱
        
        Args:
            codef_card_data (Dict): Codef API에서 받은 카드 데이터
        
        Returns:
            Dict: 파싱된 카드 데이터 {
                "card_name": str,
                "company": str,
                "card_image_url": str,
                "annual_fee_domestic": int,
                "annual_fee_overseas": int,
                "fee_waiver_rule": str,
                ...
            }
        """
        try:
            parsed = {
                "card_name": codef_card_data.get('cardName', 'Unknown Card'),
                "company": codef_card_data.get('issuer', 'Unknown Company'),
                "card_image_url": codef_card_data.get('imageUrl', ''),
                "annual_fee_domestic": int(codef_card_data.get('annualFeeDomestic', 0)),
                "annual_fee_overseas": int(codef_card_data.get('annualFeeOverseas', 0)),
                "fee_waiver_rule": codef_card_data.get('feeWaiverRule', ''),
                "baseline_requirements_text": codef_card_data.get('baselineRequirements', ''),
                "benefit_cap_summary": codef_card_data.get('benefitSummary', ''),
            }
            
            return parsed
            
        except Exception as e:
            logger.error(f"Error parsing card data: {str(e)}")
            raise

    def create_connected_id(
        self,
        organization: str,
        card_id: str = "",
        password: str = "",
        card_no: str = "",
        card_password: str = "",
        login_type: str = "1",
        user_name: str = "",
        phone_no: str = "",
        identity: str = "",
        telecom: str = "",
        two_way_info: Dict = None
    ) -> Dict:
        """
        Connected ID 발급 (간편인증 지원)
        """
        try:
            # 1. 액세스 토큰 확인
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            url = f"{self.CODEF_DEV_API_URL}/v1/account/create"
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            # 계정 정보 구성
            account_info = {
                "countryCode": "KR",
                "businessType": "CD",
                "clientType": "P",
                "organization": organization,
                "loginType": login_type,
            }

            # 로그인 타입별 필드 설정
            if login_type == "1":
                account_info.update({
                    "id": card_id,
                    "password": password,
                })
            elif login_type == "4": # 간편인증
                # 기본값은 토스(4)이지만 프론트엔드에서 받지 않았다면 토스로 설정
                # 프론트엔드에서 login_type_level을 보내주면 그것을 사용
                login_type_level = two_way_info.get("loginTypeLevel") if (two_way_info and "loginTypeLevel" in two_way_info) else "4"
                
                account_info.update({
                    "loginTypeLevel": login_type_level, 
                    "userName": user_name,
                    "phoneNo": phone_no,
                    "identity": identity,
                    "telecom": telecom
                })

            # 추가 정보 (카드번호 등)
            if card_no: account_info["cardNo"] = card_no
            if card_password: account_info["cardPassword"] = card_password

            # **2차 인증(Two-way) 요청인 경우**
            if two_way_info:
                account_info["isTwoWay"] = True
                account_info["simpleAuth"] = two_way_info

            payload = {"accountList": [account_info]}
            
            response = requests.post(
                url, 
                data=json.dumps(payload), 
                headers=headers, 
                timeout=45 # 인증 대기 시간 고려 증가
            )
            
            # 응답 본문이 비어있는 경우를 대비하여 텍스트 먼저 확인
            if not response.text:
                logger.error(f"Empty response from Codef API. Status: {response.status_code}")
                return {
                    "success": False,
                    "error_message": f"Codef API returned empty response (Status: {response.status_code})"
                }

            try:
                # Codef 로부터 받은 응답이 URL 인코딩 되어있는 경우 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote_plus(response_text)
                        api_response = json.loads(decoded_text)
                    except Exception:
                        # 디코딩 실패 시 원본으로 다시 시도
                         api_response = response.json()
                else:
                    api_response = response.json()
                    
            except json.JSONDecodeError:
                 logger.error(f"Invalid JSON response from Codef API: {response.text}")
                 # 응답 내용을 에러 메시지에 일부 포함하여 디버깅 돕기
                 return {
                    "success": False,
                    "error_message": f"Invalid JSON response from Codef API (Status: {response.status_code}): {response.text[:200]}"
                 }
                 
            # response.raise_for_status() # 401 등 에러 응답도 JSON에 상세 메시지가 있을 수 있으므로 제거하고 아래에서 처리

            # API 응답 처리
            result_code = api_response.get('result', {}).get('code')
            result_message = api_response.get('result', {}).get('message')

            # 1. 성공 (Connected ID 발급 완료)
            if response.status_code == 200 and result_code == 'CF-00000':
                connected_id = api_response.get('data', {}).get('connectedId')
                if connected_id:
                    logger.info(f"Successfully created connected ID: {connected_id}")
                    return {
                        "success": True,
                        "connected_id": connected_id
                    }
            
            # 2. 추가 인증 필요 (CF-03002) - 앱 푸시 발송됨
            elif result_code == 'CF-03002':
                return {
                    "success": False,
                    "is_2fa": True,
                    "message": result_message,
                    "two_way_info": api_response.get('data', {}) # 다음 요청에 필요
                }

            # 3. 실패
            else:
                # Codef 에러 메시지 추출 시도
                # 1. result.message 확인
                error_msg = api_response.get('result', {}).get('message')
                
                # 2. error_description (OAuth 에러 등) 확인
                if not error_msg:
                    error_msg = api_response.get('error_description')
                
                # 3. error (간략 에러) 확인
                if not error_msg:
                    error_msg = api_response.get('error')

                # 4. 없으면 기본 메시지
                if not error_msg:
                    error_msg = f"Unknown error (HTTP {response.status_code})"

                # 메시지가 URL 인코딩되어 있을 수 있으므로 디코딩 시도
                if error_msg and ('+' in error_msg or '%' in error_msg):
                    try:
                         error_msg = urllib.parse.unquote_plus(error_msg)
                    except Exception as e:
                        logger.debug(f"Failed to decode error message: {e}")

                logger.error(f"Codef API error: {error_msg}")
                
                return {
                    "success": False,
                    "error_message": error_msg
                }
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Codef API request failed: {str(e)}")
            return {
                "success": False,
                "error_message": f"API request failed: {str(e)}"
            }
        except Exception as e:
            logger.error(f"Unexpected error in create_connected_id: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }

    def get_card_list(
        self,
        organization: str,
        connected_id: str,
        birth_date: str = "",
        card_no: str = "",
        card_password: str = "",
        inquiry_type: str = "0"
    ) -> Dict:
        """
        보유 카드 목록 조회
        
        Args:
            organization (str): 기관 코드
            connected_id (str): Connected ID
            birth_date (str): 생년월일 (선택)
            card_no (str): 카드 번호 (선택)
            card_password (str): 카드 비밀번호 (선택)
            inquiry_type (str): 조회 구분 (기본값 "0")
            
        Returns:
            Dict: 카드 목록 조회 결과
        """
        try:
            # 1. 액세스 토큰 확인 (없으면 새로 발급)
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            # 2. 카드 목록 조회 요청
            url = f"{self.CODEF_DEV_API_URL}/v1/kr/card/p/account/card-list"
            
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "organization": organization,
                "connectedId": connected_id,
                "cardNo": card_no,
                "cardPassword": card_password,
                "birthDate": birth_date,
                "inquiryType": inquiry_type
            }
            
            response = requests.post(
                url, 
                data=json.dumps(payload), 
                headers=headers, 
                timeout=30
            )
            
            if not response.text:
                logger.error(f"Empty response from Codef API. Status: {response.status_code}")
                return {
                    "success": False,
                    "error_message": f"Codef API returned empty response (Status: {response.status_code})"
                }

            try:
                # URL 인코딩 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote(response_text)
                        api_response = json.loads(decoded_text)
                    except Exception:
                        api_response = response.json()
                else:
                    api_response = response.json()
                    
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON response from Codef API: {response.text}")
                return {
                    "success": False,
                    "error_message": f"Invalid JSON response from Codef API (Status: {response.status_code}): {response.text[:200]}"
                }

            result_code = api_response.get('result', {}).get('code')
            
            if response.status_code == 200 and result_code in ['00000', 'CF-00000']:
                data = api_response.get('data', [])
                if isinstance(data, dict):
                    # 단일 객체나 다른 형태로 오는 경우 리스트로 감싸거나 처리
                    # Codef 문서를 보면 data가 리스트인 경우도 있고, dict인 경우도 있을 수 있음
                    # 하지만 보통 목록 조회는 list로 옴. 
                    # 만약 data가 dict라면 list로 변환 혹은 그대로 반환
                     data = [data] # 안전하게 리스트로 감싸기보다는 확인 필요. 보통은 list
                     # 여기서는 사용자가 예시로 준 응답 형식이 Item 구조 하나임. 
                     # data 필드 자체가 list인지, data 필드 안에 list가 있는지 확인 필요.
                     # "resCardNo" 등이 바로 나오는 경우라면 data는 list가 아님.
                     # 하지만 "보유한 카드 목록" 이므로 data가 list일 가능성이 높음.
                     # API 응답 구조에 따라 유연하게 처리
                     pass
                
                # API 응답의 data 필드 자체를 반환 (보통 리스트 형태 | 혹은 딕셔너리)
                return {
                    "success": True,
                    "data": api_response.get('data')
                }
            else:
                error_msg = api_response.get('result', {}).get('message')
                if not error_msg:
                    error_msg = api_response.get('error_description') or api_response.get('error') or f"Unknown error (HTTP {response.status_code})"

                logger.error(f"Codef API error: {error_msg}")
                return {
                    "success": False,
                    "error_message": error_msg
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Codef API request failed: {str(e)}")
            return {
                "success": False,
                "error_message": f"API request failed: {str(e)}"
            }
        except Exception as e:
            logger.error(f"Unexpected error in get_card_list: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }

    def get_billing_list(
        self,
        organization: str,
        connected_id: str,
        birth_date: str = "",
        card_no: str = "",
        card_password: str = "",
        inquiry_type: str = "0"
    ) -> Dict:
        """
        보유 카드 청구 내역 조회
        
        Args:
            organization (str): 기관 코드
            connected_id (str): Connected ID
            birth_date (str): 생년월일 (선택)
            card_no (str): 카드 번호 (선택)
            card_password (str): 카드 비밀번호 (선택)
            inquiry_type (str): 조회 구분 (기본값 "0")
            
        Returns:
            Dict: 청구 내역 조회 결과
        """
        try:
            # 1. 액세스 토큰 확인
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            # 2. 청구 내역 조회 요청
            url = f"{self.CODEF_DEV_API_URL}/v1/kr/card/p/account/billing-list"
            
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "organization": organization,
                "connectedId": connected_id,
                "cardNo": card_no,
                "cardPassword": card_password,
                "birthDate": birth_date,
                "inquiryType": inquiry_type
            }
            
            response = requests.post(
                url, 
                data=json.dumps(payload), 
                headers=headers, 
                timeout=30
            )
            
            if not response.text:
                return {
                    "success": False,
                    "error_message": f"Codef API returned empty response (Status: {response.status_code})"
                }

            try:
                # URL 인코딩 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote(response_text)
                        api_response = json.loads(decoded_text)
                    except Exception:
                        api_response = response.json()
                else:
                    api_response = response.json()
                    
            except json.JSONDecodeError:
                return {
                    "success": False,
                    "error_message": f"Invalid JSON response from Codef API"
                }

            result_code = api_response.get('result', {}).get('code')
            
            if response.status_code == 200 and result_code in ['00000', 'CF-00000']:
                return {
                    "success": True,
                    "data": api_response.get('data')
                }
            else:
                error_msg = api_response.get('result', {}).get('message')
                if not error_msg:
                    error_msg = api_response.get('error_description') or api_response.get('error') or "Unknown Codef Error"

                logger.error(f"Codef API error: {error_msg}")
                return {
                    "success": False,
                    "error_message": error_msg
                }

        except Exception as e:
            logger.error(f"Unexpected error in get_billing_list: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }
