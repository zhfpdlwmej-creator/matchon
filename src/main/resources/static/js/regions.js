/* 한국 행정구역 2단계 (시/도 → 시/군/구) + 지역 선택 UI 헬퍼 */
(function (global) {
	const REGIONS = {
		"서울특별시": ["종로구","중구","용산구","성동구","광진구","동대문구","중랑구","성북구","강북구","도봉구","노원구","은평구","서대문구","마포구","양천구","강서구","구로구","금천구","영등포구","동작구","관악구","서초구","강남구","송파구","강동구"],
		"부산광역시": ["중구","서구","동구","영도구","부산진구","동래구","남구","북구","해운대구","사하구","금정구","강서구","연제구","수영구","사상구","기장군"],
		"대구광역시": ["중구","동구","서구","남구","북구","수성구","달서구","달성군","군위군"],
		"인천광역시": ["중구","동구","미추홀구","연수구","남동구","부평구","계양구","서구","강화군","옹진군"],
		"광주광역시": ["동구","서구","남구","북구","광산구"],
		"대전광역시": ["동구","중구","서구","유성구","대덕구"],
		"울산광역시": ["중구","남구","동구","북구","울주군"],
		"세종특별자치시": ["세종시"],
		"경기도": ["수원시","성남시","의정부시","안양시","부천시","광명시","평택시","동두천시","안산시","고양시","과천시","구리시","남양주시","오산시","시흥시","군포시","의왕시","하남시","용인시","파주시","이천시","안성시","김포시","화성시","광주시","양주시","포천시","여주시","연천군","가평군","양평군"],
		"강원특별자치도": ["춘천시","원주시","강릉시","동해시","태백시","속초시","삼척시","홍천군","횡성군","영월군","평창군","정선군","철원군","화천군","양구군","인제군","고성군","양양군"],
		"충청북도": ["청주시","충주시","제천시","보은군","옥천군","영동군","증평군","진천군","괴산군","음성군","단양군"],
		"충청남도": ["천안시","공주시","보령시","아산시","서산시","논산시","계룡시","당진시","금산군","부여군","서천군","청양군","홍성군","예산군","태안군"],
		"전북특별자치도": ["전주시","군산시","익산시","정읍시","남원시","김제시","완주군","진안군","무주군","장수군","임실군","순창군","고창군","부안군"],
		"전라남도": ["목포시","여수시","순천시","나주시","광양시","담양군","곡성군","구례군","고흥군","보성군","화순군","장흥군","강진군","해남군","영암군","무안군","함평군","영광군","장성군","완도군","진도군","신안군"],
		"경상북도": ["포항시","경주시","김천시","안동시","구미시","영주시","영천시","상주시","문경시","경산시","의성군","청송군","영양군","영덕군","청도군","고령군","성주군","칠곡군","예천군","봉화군","울진군","울릉군"],
		"경상남도": ["창원시","진주시","통영시","사천시","김해시","밀양시","거제시","양산시","의령군","함안군","창녕군","고성군","남해군","하동군","산청군","함양군","거창군","합천군"],
		"제주특별자치도": ["제주시","서귀포시"]
	};
	global.REGIONS = REGIONS;

	function esc(s) { return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

	/**
	 * 지역 선택 UI 생성.
	 * container 안에 시/도 줄 + 시군구 줄을 만든다.
	 * opts = { onChange(regionStr, sido, sigungu), includeAll(bool), initial(string) }
	 */
	global.buildRegionPicker = function (container, opts) {
		opts = opts || {};
		const $c = (typeof container === 'string') ? document.querySelector(container) : container;
		$c.innerHTML =
			'<div class="region-row" data-role="sido"></div>' +
			'<div class="region-row" data-role="sigungu" style="margin-top:8px;"></div>';
		const sidoRow = $c.querySelector('[data-role=sido]');
		const sgRow = $c.querySelector('[data-role=sigungu]');
		let selSido = null, selSg = null;

		function emit() {
			let region = '';
			if (selSido) region = selSg ? (selSido + ' ' + selSg) : selSido;
			if (opts.onChange) opts.onChange(region, selSido, selSg);
		}
		function chip(text, on) {
			return '<button type="button" class="region-chip' + (on ? ' on' : '') + '">' + esc(text) + '</button>';
		}
		function renderSido() {
			let html = opts.includeAll ? chip('전체', selSido === null) : '';
			Object.keys(REGIONS).forEach(s => { html += chip(shortName(s), selSido === s); });
			sidoRow.innerHTML = html;
		}
		function renderSigungu() {
			if (!selSido) { sgRow.innerHTML = ''; return; }
			let html = opts.includeAll ? chip(shortName(selSido) + ' 전체', selSg === null) : '';
			REGIONS[selSido].forEach(g => { html += chip(g, selSg === g); });
			sgRow.innerHTML = html;
		}
		// 짧은 표기 (서울특별시 → 서울, 경기도 → 경기, 강원특별자치도 → 강원)
		function shortName(s) {
			return s.replace('특별자치도','').replace('특별자치시','').replace('특별시','').replace('광역시','').replace(/도$/,'');
		}

		sidoRow.addEventListener('click', function (e) {
			const btn = e.target.closest('.region-chip'); if (!btn) return;
			const idx = [...sidoRow.children].indexOf(btn);
			if (opts.includeAll && idx === 0) { selSido = null; selSg = null; }
			else { const keys = Object.keys(REGIONS); selSido = keys[opts.includeAll ? idx - 1 : idx]; selSg = null; }
			renderSido(); renderSigungu(); emit();
		});
		sgRow.addEventListener('click', function (e) {
			const btn = e.target.closest('.region-chip'); if (!btn) return;
			const idx = [...sgRow.children].indexOf(btn);
			if (opts.includeAll && idx === 0) { selSg = null; }
			else { selSg = REGIONS[selSido][opts.includeAll ? idx - 1 : idx]; }
			renderSigungu(); emit();
		});

		renderSido(); renderSigungu();
		return { get: () => (selSido ? (selSg ? selSido + ' ' + selSg : selSido) : '') };
	};
})(window);
