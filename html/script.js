// ============================================================================
// KURAI CRAFTING - MODERN UI SCRIPT
// ============================================================================

let currentStation = null;
let playerData = null;
let currentCategory = 'all';
let selectedRecipe = null;
let allRecipes = {};

// ============================================================================
// NUI CALLBACKS
// ============================================================================

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'openCrafting':
            openCrafting(data.station, data.data);
            break;
        case 'closeCrafting':
            closeCrafting();
            break;
        case 'updateData':
            updatePlayerData(data.data);
            break;
        case 'notify':
            showNotification(data.title, data.message, data.type);
            break;
    }
});

// ============================================================================
// UI CONTROL
// ============================================================================

function openCrafting(station, data) {
    currentStation = station;
    playerData = data;
    allRecipes = {...data.recipes, ...data.lockedRecipes};
    
    $('.station-name').text(station.label || 'Crafting Station');
    updatePlayerStats();
    renderCategories();
    renderRecipes();
    
    $('.app-container').addClass('show');
    $.post('https://KuraiCrafting/uiReady');
}

function closeCrafting() {
    $('.app-container').removeClass('show');
    currentStation = null;
    playerData = null;
    currentCategory = 'all';
    selectedRecipe = null;
    $('#detailsPanel').find('.details-content').html(`
        <div class="details-empty">
            <i class="fas fa-arrow-left"></i>
            <p>Select a recipe to view details</p>
        </div>
    `);
    $('#craftActions').hide();
    $.post('https://KuraiCrafting/closeUI');
}

function updatePlayerData(data) {
    playerData = data;
    updatePlayerStats();
}

function updatePlayerStats() {
    $('#playerLevel').text(playerData.level);
    $('#playerTitle').text(playerData.title);
    
    const xpPercent = (playerData.xp / playerData.nextLevelXP) * 100;
    $('#xpFill').css('width', xpPercent + '%');
    $('#xpText').text(`${playerData.xp} / ${playerData.nextLevelXP}`);
    
    if (playerData.specialization) {
        $('#specName').text(playerData.specialization.label || 'Active');
    } else {
        $('#specName').text('None');
    }
}

// ============================================================================
// CATEGORIES
// ============================================================================

function renderCategories() {
    const categories = {};
    const stationConfig = currentStation.type;
    
    // Count recipes per category
    Object.keys(playerData.recipes).forEach(id => {
        const recipe = playerData.recipes[id];
        if (!categories[recipe.category]) {
            categories[recipe.category] = {available: 0, locked: 0};
        }
        categories[recipe.category].available++;
    });
    
    if (playerData.lockedRecipes) {
        Object.keys(playerData.lockedRecipes).forEach(id => {
            const recipe = playerData.lockedRecipes[id].recipe;
            if (!categories[recipe.category]) {
                categories[recipe.category] = {available: 0, locked: 0};
            }
            categories[recipe.category].locked++;
        });
    }
    
    const categoryIcons = {
        basic: 'fa-box',
        tools: 'fa-wrench',
        components: 'fa-gears',
        electronics: 'fa-microchip',
        weapons: 'fa-gun',
        attachments: 'fa-crosshairs',
        ammo: 'fa-boxes-stacked',
        medical: 'fa-briefcase-medical',
        chemistry: 'fa-flask',
        food: 'fa-burger',
        drinks: 'fa-mug-hot'
    };
    
    let html = `
        <div class="category-item ${currentCategory === 'all' ? 'active' : ''}" data-category="all">
            <div class="category-left">
                <i class="fas fa-list category-icon"></i>
                <span class="category-name">All Recipes</span>
            </div>
            <span class="category-count">${Object.keys(playerData.recipes).length}</span>
        </div>
    `;
    
    Object.keys(categories).sort().forEach(cat => {
        const count = categories[cat].available;
        const total = count + categories[cat].locked;
        const icon = categoryIcons[cat] || 'fa-box';
        const isActive = currentCategory === cat;
        
        html += `
            <div class="category-item ${isActive ? 'active' : ''}" data-category="${cat}">
                <div class="category-left">
                    <i class="fas ${icon} category-icon"></i>
                    <span class="category-name">${capitalize(cat)}</span>
                </div>
                <span class="category-count">${count}/${total}</span>
            </div>
        `;
    });
    
    $('#categoryList').html(html);
}

// ============================================================================
// RECIPES
// ============================================================================

function renderRecipes() {
    const searchTerm = $('#searchInput').val().toLowerCase();
    let recipesToShow = [];
    
    // Available recipes
    Object.keys(playerData.recipes).forEach(id => {
        const recipe = playerData.recipes[id];
        if (matchesFilter(recipe, searchTerm)) {
            recipesToShow.push({id, recipe, locked: false});
        }
    });
    
    // Locked recipes
    if (playerData.lockedRecipes) {
        Object.keys(playerData.lockedRecipes).forEach(id => {
            const lockedData = playerData.lockedRecipes[id];
            const recipe = lockedData.recipe;
            if (matchesFilter(recipe, searchTerm)) {
                recipesToShow.push({id, recipe, locked: true, lockReason: lockedData.reason});
            }
        });
    }
    
    if (recipesToShow.length === 0) {
        $('#recipeGrid').hide();
        $('#emptyState').show();
        return;
    }
    
    $('#emptyState').hide();
    $('#recipeGrid').show();
    
    let html = '';
    recipesToShow.forEach(({id, recipe, locked, lockReason}) => {
        const ingredientsHtml = recipe.ingredients.map(ing => 
            `<span class="ingredient-tag">${ing.count}x ${ing.item}</span>`
        ).join('');
        
        const qualityTag = recipe.canProduceQuality ? 
            '<span class="recipe-tag quality"><i class="fas fa-sparkles"></i> Quality</span>' : '';
        
        const lockedTag = locked ? 
            '<span class="recipe-tag locked-tag"><i class="fas fa-lock"></i> Locked</span>' : '';
        
        const levelClass = locked ? 'locked' : '';
        const activeClass = selectedRecipe === id ? 'active' : '';
        
        html += `
            <div class="recipe-card ${levelClass} ${activeClass}" data-recipe="${id}" data-locked="${locked}">
                <div class="recipe-header">
                    <div>
                        <div class="recipe-title">${recipe.label}</div>
                        <div class="recipe-category">${recipe.category}</div>
                    </div>
                    <div class="recipe-level">Lv ${recipe.requiredLevel}</div>
                </div>
                
                <div class="recipe-ingredients">
                    <span class="ingredient-label">Required Materials</span>
                    <div class="ingredient-list">${ingredientsHtml}</div>
                </div>
                
                <div class="recipe-footer">
                    <span class="recipe-xp"><i class="fas fa-star"></i> ${recipe.xp} XP</span>
                    <div class="recipe-tags">
                        ${qualityTag}
                        ${lockedTag}
                    </div>
                </div>
            </div>
        `;
    });
    
    $('#recipeGrid').html(html);
}

function matchesFilter(recipe, searchTerm) {
    // Category filter
    if (currentCategory !== 'all' && recipe.category !== currentCategory) {
        return false;
    }
    
    // Search filter
    if (searchTerm) {
        const labelMatch = recipe.label.toLowerCase().includes(searchTerm);
        const categoryMatch = recipe.category.toLowerCase().includes(searchTerm);
        const descMatch = (recipe.description || '').toLowerCase().includes(searchTerm);
        
        if (!labelMatch && !categoryMatch && !descMatch) {
            return false;
        }
    }
    
    return true;
}

function showRecipeDetails(recipeId) {
    selectedRecipe = recipeId;
    
    // Update active state
    $('.recipe-card').removeClass('active');
    $(`.recipe-card[data-recipe="${recipeId}"]`).addClass('active');
    
    const isLocked = $(`.recipe-card[data-recipe="${recipeId}"]`).data('locked');
    let recipe;
    
    if (isLocked) {
        recipe = playerData.lockedRecipes[recipeId].recipe;
    } else {
        recipe = playerData.recipes[recipeId];
    }
    
    // Update title and badges
    $('#detailsTitle').text(recipe.label);
    
    let badgesHtml = `
        <span class="badge level"><i class="fas fa-layer-group"></i> Level ${recipe.requiredLevel}</span>
        <span class="badge xp"><i class="fas fa-star"></i> ${recipe.xp} XP</span>
    `;
    
    if (recipe.canProduceQuality) {
        badgesHtml += '<span class="badge quality"><i class="fas fa-sparkles"></i> Quality Crafting</span>';
    }
    
    $('#recipeBadges').html(badgesHtml);
    
    // Build details content
    let detailsHtml = '';
    
    // Description
    if (recipe.description) {
        detailsHtml += `
            <div class="detail-section">
                <h3>Description</h3>
                <p style="color: var(--text-secondary); line-height: 1.6;">${recipe.description}</p>
            </div>
        `;
    }
    
    // Result
    detailsHtml += `
        <div class="detail-section">
            <h3>Result</h3>
            <div class="result-preview">
                <div class="result-icon"><i class="fas fa-box-open"></i></div>
                <div class="result-name">${recipe.result.item}</div>
                <div class="result-count">${recipe.result.count}x per craft</div>
            </div>
        </div>
    `;
    
    // Ingredients
    detailsHtml += `
        <div class="detail-section">
            <h3>Required Materials</h3>
            <div class="detail-list">
    `;
    
    recipe.ingredients.forEach(ing => {
        detailsHtml += `
            <div class="detail-item">
                <span class="detail-item-label">${ing.item}</span>
                <span class="detail-item-value">${ing.count}x</span>
            </div>
        `;
    });
    
    detailsHtml += '</div></div>';
    
    // Tool requirement
    if (recipe.requiredTool) {
        detailsHtml += `
            <div class="detail-section">
                <h3>Required Tool</h3>
                <div class="detail-list">
                    <div class="detail-item">
                        <span class="detail-item-label"><i class="fas fa-wrench"></i> ${recipe.requiredTool}</span>
                        <span class="detail-item-value">Required</span>
                    </div>
                </div>
            </div>
        `;
    }
    
    // Craft time
    if (recipe.time) {
        detailsHtml += `
            <div class="detail-section">
                <h3>Crafting Info</h3>
                <div class="detail-list">
                    <div class="detail-item">
                        <span class="detail-item-label">Craft Time</span>
                        <span class="detail-item-value">${(recipe.time / 1000).toFixed(1)}s</span>
                    </div>
                </div>
            </div>
        `;
    }
    
    $('#detailsContent').html(detailsHtml);
    
    // Show/hide craft button
    if (isLocked) {
        $('#craftActions').hide();
    } else {
        $('#craftActions').show();
        $('#craftAmount').val(1);
    }
}

// ============================================================================
// SPECIALIZATION
// ============================================================================

function openSpecializationModal() {
    const specs = playerData.specializationData;
    if (!specs) return;
    
    let html = '';
    
    if (specs.current) {
        const currentSpec = specs.current;
        html += `
            <div class="current-spec">
                <div class="current-spec-header">
                    <i class="fas ${currentSpec.icon}" style="font-size: 24px; color: var(--primary-light);"></i>
                    <div>
                        <h3 style="margin: 0;">${currentSpec.label}</h3>
                        <p style="margin: 4px 0 0 0; color: var(--text-muted); font-size: 13px;">Current Specialization</p>
                    </div>
                </div>
                <p style="color: var(--text-secondary); margin: 12px 0;">${currentSpec.description}</p>
                
                ${specs.canReset ? `
                    <button class="reset-spec-btn" onclick="resetSpecialization()">
                        <i class="fas fa-rotate-left"></i> 
                        Reset Specialization ${specs.resetCost > 0 ? '($' + specs.resetCost + ')' : '(Free)'}
                    </button>
                ` : ''}
            </div>
        `;
    } else {
        html += '<h3 style="margin-bottom: 16px;">Choose Your Specialization</h3>';
    }
    
    if (!specs.current) {
        html += '<div class="specialization-grid">';
        
        Object.keys(specs.available).forEach(specId => {
            const spec = specs.available[specId];
            const bonusCategories = spec.bonusCategories.join(', ');
            
            html += `
                <div class="spec-card" onclick="selectSpecialization('${specId}')">
                    <div class="spec-header">
                        <i class="fas ${spec.icon} spec-icon" style="color: ${spec.color};"></i>
                        <div class="spec-title">${spec.label}</div>
                    </div>
                    <div class="spec-description">${spec.description}</div>
                    <div class="spec-bonuses">
                        <div class="spec-bonus-item">
                            <i class="fas fa-check"></i>
                            +${Math.floor(spec.xpBonus * 100)}% XP in ${bonusCategories}
                        </div>
                        <div class="spec-bonus-item">
                            <i class="fas fa-check"></i>
                            +${Math.floor(spec.qualityBonus * 100)}% Quality Chance
                        </div>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
    }
    
    $('#specializationContent').html(html);
    $('#specializationModal').fadeIn(200);
}

function selectSpecialization(specType) {
    $.post('https://KuraiCrafting/selectSpecialization', JSON.stringify({
        specialization: specType
    }));
    $('#specializationModal').fadeOut(200);
}

function resetSpecialization() {
    $.post('https://KuraiCrafting/resetSpecialization');
    $('#specializationModal').fadeOut(200);
}

// ============================================================================
// CRAFTING
// ============================================================================

function craftItem() {
    if (!selectedRecipe) return;
    
    const amount = parseInt($('#craftAmount').val()) || 1;
    
    $.post('https://KuraiCrafting/craftItem', JSON.stringify({
        recipeId: selectedRecipe,
        amount: amount
    }));
    
    closeCrafting();
}

// ============================================================================
// NOTIFICATIONS
// ============================================================================

function showNotification(title, message, type = 'info') {
    const icons = {
        success: 'fa-check-circle',
        error: 'fa-times-circle',
        warning: 'fa-exclamation-triangle',
        info: 'fa-info-circle'
    };
    
    const icon = icons[type] || icons.info;
    
    const notification = $(`
        <div class="notification ${type}">
            <i class="fas ${icon} notification-icon"></i>
            <div class="notification-content">
                <div class="notification-title">${title}</div>
                <div class="notification-message">${message}</div>
            </div>
        </div>
    `);
    
    $('#notificationContainer').append(notification);
    
    setTimeout(() => {
        notification.fadeOut(300, function() {
            $(this).remove();
        });
    }, 4000);
}

// ============================================================================
// EVENT HANDLERS
// ============================================================================

$(document).ready(function() {
    // Close button
    $('#closeBtn').click(closeCrafting);
    
    // Category selection
    $(document).on('click', '.category-item', function() {
        currentCategory = $(this).data('category');
        $('.category-item').removeClass('active');
        $(this).addClass('active');
        renderRecipes();
    });
    
    // Recipe selection
    $(document).on('click', '.recipe-card', function() {
        const isLocked = $(this).data('locked');
        if (isLocked) return;
        
        const recipeId = $(this).data('recipe');
        showRecipeDetails(recipeId);
    });
    
    // Search
    $('#searchInput').on('input', function() {
        renderRecipes();
    });
    
    // Amount controls
    $('#increaseAmount').click(function() {
        const current = parseInt($('#craftAmount').val()) || 1;
        $('#craftAmount').val(Math.min(current + 1, 25));
    });
    
    $('#decreaseAmount').click(function() {
        const current = parseInt($('#craftAmount').val()) || 1;
        $('#craftAmount').val(Math.max(current - 1, 1));
    });
    
    // Craft button
    $('#craftBtn').click(craftItem);
    
    // Specialization
    $('#specializationBtn').click(function() {
        $.post('https://KuraiCrafting/openSpecialization');
    });
    
    $('#closeSpecModal').click(function() {
        $('#specializationModal').fadeOut(200);
    });
    
    // ESC key
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            if ($('#specializationModal').is(':visible')) {
                $('#specializationModal').fadeOut(200);
            } else {
                closeCrafting();
            }
        }
    });
});

// ============================================================================
// UTILITY
// ============================================================================

function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}
